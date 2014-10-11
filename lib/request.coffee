conf = require './conf'
Rest = require 'restler'
_ = require 'underscore'
Q = require 'q'
write = require './write'
CoffeeScript = require 'coffee-script'
httpStatus = require 'http-status'
error = require './error'
Headers = require './headers'
t = require 'exectimer'

toObject = ( data ) ->
  try data = JSON.parse data if typeof data is "string"
  catch e
  data


_send = ( url, options ) ->

path = ( r, id ) -> if id? then "/r/#{id}" else "/#{r}"

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

    if opts.verbose
      write { apiName : apiName, config : apiConfig }
      write ""

    @options.method = opts.op or throw "no op"

    Headers @options.headers, apiConfig.headers
    Headers @options.headers, opts.header

    @options.query.where = opts.where if opts.where?
    if opts.query?
      try
        _.extend @options.query, CoffeeScript.eval( opts.query )
      catch err
        return Q.reject { error : { message : err.message + ". Please check syntax of the 'query' option." } }

    if opts.data?
      try
        _.extend @options.data, CoffeeScript.eval( opts.data )
      catch err
        return Q.reject { error : { message : err.message + ". Please check syntax of the 'data' option." } }

    delete @options.data if  _.isEmpty @options.data
    if @options.data
      @options.headers[ "Content-type" ] = "application/json"
      @options.data = JSON.stringify @options.data

    delete @options.headers if  _.isEmpty @options.headers
    delete @options.query if  _.isEmpty @options.query

    @url = "#{apiConfig.url}#{path( opts.resource, opts.id )}"
    if opts.verbose
      write request : { url : @url, options : @options }, opts
      write ""
      write "Response"

  send : =>
    d = Q.defer()
    tick = new t.Tick "request"
    tick.start()

    Rest.request @url, @options
    .on 'success', ( data, res ) -> d.resolve [ toObject( data ), res ]
    .on 'error', ( err, res ) -> d.reject err
    .on 'timeout', ( ms ) -> d.reject message : "timeout #{ms}", statusCode : 408
    .on 'fail', ( data, res ) -> d.reject [ toObject( data ), res ]

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
    new Request( opts ).send()
  catch err
    Q.reject [ err ]

module.exports = exports = ( cmd ) -> ( opts ) ->
  opts.op = cmd
  request opts

  .then ( [data, res, timer] ) ->
    code = httpStatus[ res.statusCode ].toUpperCase()
    write "> HTTP #{res.statusCode} #{code}, #{timer.duration() / 1000000} ms."
    write data, opts

  .fail ( [err, res, timer] ) ->
    if err? and timer?
      code = httpStatus[ res.statusCode ].toUpperCase()
      write "> HTTP #{res.statusCode} #{code}, #{timer.duration() / 1000000} ms."
    write err, opts
