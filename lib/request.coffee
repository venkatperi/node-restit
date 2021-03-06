conf = require './conf'
Rest = require 'restler'
_ = require 'underscore'
Q = require 'q'
write = require './write'
httpStatus = require 'http-status'
error = require './error'
Headers = require './headers'
t = require 'exectimer'
mediaType = require 'media-type'
jpath = require "JSONpath"
cson = require 'cson'

#parseCson = Q.nfbind cson.parse
parseCson = ( str ) ->
  d = Q.defer()
  cson.parse str, ( err, obj ) ->
    return d.reject err if err?
    d.resolve obj
  d.promise


safeParse = ( data ) ->
  return unless data?
  try data = JSON.parse data if typeof data is "string"
  catch e
  data

path = ( r, id ) -> if id? then "/r/#{id}" else "/#{r}"

helpers = """
base64 = (str) -> new Buffer(str).toString('base64')
"""

class Request
  options :
    headers : {}
    query : {}
    data : {}
    method : "get"

  url : null

  constructor : ( opts ) ->
    apiName = opts.api or conf.get "api:default"
    throw error "API name missing" unless apiName?
    apiConfig = conf.get "api:#{apiName}"
    throw error "API not found in config" unless apiConfig?

    @options.method = opts.op or throw "no op"
    @options.query.where = opts.where if opts.where?
    @url = "#{apiConfig.url}#{path( opts.resource, opts.id )}"
    promise = Q()

    if opts.query?
      promise = promise
      .then => parseCson( opts.query )
      .then ( obj ) => @options.query = obj

    if opts.data?
      promise = promise
      .then => parseCson( opts.data )
      .then ( obj ) => @options.data = obj

    @promise = promise
    .then =>
      Headers @options.headers, apiConfig.headers
      Headers @options.headers, opts.header

      if _.isEmpty @options.data
        delete @options.data
      else if not opts[ "nojson" ] and not @options.headers[ 'Content-Type' ]?
        @options.headers[ "Content-Type" ] = "application/json"

      if @options.headers[ 'Content-Type' ]?
        mt = mediaType.fromString @options.headers[ "Content-Type" ]
        return Q.reject { error : { message : "Bad media type" } } unless mt.isValid()
        if mt.type is "application" and mt.subtype is "json"
          @options.data = JSON.stringify @options.data

      delete @options.headers if  _.isEmpty @options.headers
      delete @options.query if  _.isEmpty @options.query

      if opts.verbose
        write { apiName : apiName, config : apiConfig }
        write request : { url : @url, options : @options }, opts
        write ""

    @promise.done()

  send : =>
    @promise
    .then =>
      d = Q.defer()
      tick = new t.Tick "request"
      tick.start()

      Rest.request @url, @options
      .on 'success', ( data, res ) -> d.resolve [ safeParse( data ), res ]
      .on 'error', ( err, res ) -> d.reject err
      .on 'timeout', ( ms ) -> d.reject message : "timeout #{ms}", statusCode : 408
      .on 'fail', ( data, res ) -> d.reject [ safeParse( data ), res ]

      d.promise.then ( x ) ->
        tick.stop()
        x.push t.timers.request
        x
      .fail ( x ) ->
        tick.stop()
        x.push t.timers.request
        x

request = ( opts ) ->
  try
    request = new Request( opts )
    if opts.nosend then Q [ "didn't send request (--nosend was specified)", { statusCode : 200 } ] else request.send()
  catch err
    Q.reject [ err ]

module.exports = exports = ( cmd ) -> ( opts ) ->
  opts.op = cmd
  request opts

  .then ( [data, res, timer] ) ->
    code = httpStatus[ res.statusCode ].toUpperCase()
    duration = if timer? then timer.duration() / 1000000 else 0
    write "> HTTP #{res.statusCode} #{code}, #{duration} ms." unless opts[ "noinfo" ]
    if opts.jpath?
      data = jpath.eval data, opts.jpath
      data = data[ 0 ] if _.isArray( data ) and data.length == 1
    write data, opts

  .fail ( [err, res, timer] ) ->
    if err? and timer?
      code = httpStatus[ res.statusCode ].toUpperCase()
      write "> HTTP #{res.statusCode} #{code}, #{timer.duration() / 1000000} ms." unless opts[ "noinfo" ]
    write err, opts
