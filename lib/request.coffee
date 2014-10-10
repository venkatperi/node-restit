conf = require './conf'
Rest = require 'restler'
_ = require 'underscore'
Q = require 'q'
write = require './write'
CoffeeScript = require 'coffee-script'
httpStatus = require 'http-status'
error = require './error'
t = require 'exectimer'

toObject = ( data ) ->
  try data = JSON.parse data if typeof data is "string"
  catch e
  data


send = ( url, options ) ->
  d = Q.defer()
  tick = new t.Tick "request"
  tick.start()

  Rest.request url, options
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

path = ( r, id ) -> if id? then "/r/#{id}" else "/#{r}"

request = ( opts ) ->
  try
    apiName = opts.api or conf.get "api:default"
    throw error "API name missing" unless apiName?

    apiConfig = conf.get "api:#{apiName}"
    throw error "API not found in config" unless apiConfig?
    if opts.verbose
      write { apiName : apiName, config : apiConfig }
      write ""

    options = { method : opts.op }

    options.headers = _.clone apiConfig.headers if apiConfig.headers?

    if opts.where?
      options.query ?= {}
      options.query.where = opts.where

    if opts.query?
      try
        data = CoffeeScript.eval opts.query
        options.query ?= {}
        _.extend options.query, data
      catch err
        return Q.reject { error : { message : err.message + ". Please check syntax of the 'data' option." } }

    if opts.data?
      try
        data = CoffeeScript.eval opts.data
        options.data = data
      catch err
        return Q.reject { error : { message : err.message + ". Please check syntax of the 'data' option." } }

      options.headers ?= {}
      options.headers[ "Content-type" ] = "application/json"

    url = "#{apiConfig.url}#{path( opts.resource, opts.id )}"
    if opts.verbose
      write request : { url : url, options : options }
      write ""
      write "Response"

    options.data = JSON.stringify options.data if options.data?
    send url, options

  catch err
    write err

module.exports = exports = ( cmd ) -> ( opts ) ->
  opts.op = cmd
  request opts

  .then ( [data, res, timer] ) ->
    code = httpStatus[ res.statusCode ].toUpperCase()
    write "> HTTP #{res.statusCode} #{code}, #{timer.duration() / 1000000} ms."
    write data

  .fail ( [err, res, timer] ) ->
    code = httpStatus[ res.statusCode ].toUpperCase()
    write "> HTTP #{res.statusCode} #{code}, #{timer.duration() / 1000000} ms."
    write err
