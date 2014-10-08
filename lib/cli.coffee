nconf = require 'nconf'
Rest = require 'restler'
_ = require 'underscore'
Q = require 'q'

parser = require( 'nomnom' )
.option "op",
  abbr : 'o'
  choices : [ 'create', 'update', 'find', 'findOne', 'exists', 'get', 'delete', 'count' ]
  required : true
  help : "REST method"

.option "url",
  abbr : 'u'
  required : true
  help : "Api's base URL"

.option "resource",
  abbr : 'r'
  required : true
  help : "Name of the REST"

.option 'id',
  abbr : 'i'
  required : false
  help : "Instance ID"

.option 'data',
  abbr : 'd'
  required : false
  help : "request body"

.option 'where',
  abbr : 'w'
  required : false
  help : "'where' query filter"


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


toObject = ( data ) ->
  try data = JSON.parse data if typeof data is "string"
  catch e
  data

send = ( req ) ->
  d = Q.defer()
  req()
  .on 'success', ( data, res ) -> d.resolve toObject data
  .on 'error', ( err, res ) -> d.reject err
  .on 'timeout', ( ms ) -> d.reject message : "timeout #{ms}", statusCode : 408
  .on 'fail', ( data, res ) -> d.reject toObject( data or res.statusCode )
  d.promise


request = ( opts ) ->
  cmd = commands[ opts.op ]

  options =
    method : cmd.method

  if opts.where?
    options.query ?= {}
    options.query.where = opts.where

  if opts.data?
    options.data = JSON.stringify opts.data
    options.headers ?= {}
    options.headers[ "Content-type" ] = "application/json"

  url = "#{opts.url}#{cmd.path( opts.resource, opts.id )}"
  console.log url, options
  send -> Rest.request url, options

request parser.parse()
.then ( res ) -> console.log res
.fail ( err ) -> console.log err
