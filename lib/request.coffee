conf = require './conf'
Rest = require 'restler'
_ = require 'underscore'
Q = require 'q'
write = require './write'
CoffeeScript = require 'coffee-script'
httpStatus = require 'http-status'

toObject = ( data ) ->
  try data = JSON.parse data if typeof data is "string"
  catch e
  data

send = ( req ) ->
  d = Q.defer()
  req()
  .on 'success', ( data, res ) -> d.resolve [ toObject( data ), res ]
  .on 'error', ( err, res ) -> d.reject err
  .on 'timeout', ( ms ) -> d.reject message : "timeout #{ms}", statusCode : 408
  .on 'fail', ( data, res ) -> d.reject [ toObject( data ), res ]
  d.promise


commands =
  create : #/Cars Create a new instance of the model and persist it into the data source
    method : "POST"
    path : ( r ) -> "/#{r}"

  exists : #/Cars/{id}/exists Check whether a model instance exists in the data source
    method : "GET"
    path : ( r, id ) -> "/#{r}/#{id}"

  get : #/Cars/{id} Find a model instance by id from the data source
    method : "GET"
    path : ( r ) -> "/#{r}"

  update : #/Cars/{id} Update attributes for a model instance and persist it into the data source
    method : "PUT"
    path : ( r, id ) -> "/#{r}/#{id}"

  delete : #/Cars/{id} "DELETE" a model instance by id from the data source
    method : "DELETE"
    path : ( r, id ) -> "/#{r}/#{id}"

  findAll : #/Cars Find all instances of the model matched by filter from the data source
    method : "GET"
    path : ( r ) -> "/#{r}"

  findOne : #/Cars/findOne Find first instance of the model matched by filter from the data source
    method : "GET"
    path : ( r ) -> "/#{r}"


request = ( opts ) ->
  cmd = commands[ opts.op ]
  throw new Error "bad command" unless cmd?
  throw new Error "API name missing" unless opts.api?

  apiConfig = conf.get "api:#{opts.api}"
  throw new Error "API not found in config" unless apiConfig?

  options = { method : cmd.method }

  options.headers = _.clone apiConfig.headers if apiConfig.headers?

  if opts.where?
    options.query ?= {}
    options.query.where = opts.where

  if opts.data?
    try
      data = CoffeeScript.eval opts.data
      options.data = JSON.stringify data
    catch err
      return Q.reject { error : { message : err.message + ". Please check syntax of the 'data' option." } }

    options.headers ?= {}
    options.headers[ "Content-type" ] = "application/json"

  url = "#{apiConfig.url}#{cmd.path( opts.resource, opts.id )}"
  send -> Rest.request url, options

module.exports = exports = ( cmd ) -> ( opts ) ->
  opts.op = cmd
  request opts

  .then ( [data, res] ) ->
    code = httpStatus[ res.statusCode ].toUpperCase()
    write "> HTTP #{res.statusCode} #{code}"
    write data

  .fail ( [err, res] ) ->
    code = httpStatus[ res.statusCode ].toUpperCase()
    write "> HTTP #{res.statusCode} #{code}"
    write err
