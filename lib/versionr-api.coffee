Rest = require 'restler'
_ = require 'underscore'
Q = require 'q'
conf = require './../conf'

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


endPoint = "https://api.versionr.io/1"
Me = conf.get 'user'

request = ( resource, id, options ) ->
  url = "#{endPoint}/#{resource}"
  url += "/#{id}" if id?
  console.log url, options
  send -> Rest.request url, options

get = ( {id, query, resource, noAuth} = {} ) ->
  options = { method : 'get' }
  unless noAuth
    return Q.reject "Before you can use this command, you need to login with your Versionr account." unless Me?.sessionToken?
    options.headers = { "X-Versionr-Session-Token" : Me.sessionToken }

  options.query = query if query?
  request resource, id, options

put = ( {id, data, resource, noAuth} = {} ) ->
  options = { method : 'put' }
  unless noAuth
    return Q.reject "Before you can use this command, you need to login with your Versionr account." unless Me?.sessionToken?
    options.headers = { "X-Versionr-Session-Token" : Me.sessionToken }

  options.headers[ "Content-Type" ] = "application/json" if data?
  options.data = JSON.stringify data if data?
  request resource, id, options

module.exports = exports =

  signup : ( opts ) -> send -> Rest.postJson "#{endPoint}/users", opts

  login : ( opts ) -> get resource : "login", query : opts, noAuth : true

  validate : ( opts ) ->
    send -> Rest.postJson "#{endPoint}/validate", opts

  create : ( opts ) ->
    options =
      method : "post"
      data : JSON.stringify opts
      headers :
        "X-Versionr-Session-Token" : Me.sessionToken
        "Content-Type" : "application/json"
    send -> Rest.request "#{endPoint}/counters", options

  inc : ( opts ) ->
    options =
      method : "post"
      headers :
        "X-Versionr-Session-Token" : Me.sessionToken
    url = "#{endPoint}/counters/#{opts.id}/inc"
    url += "/#{opts.step}" if opts.step?
    send -> Rest.request url, options

  counters : ( opts ) ->
    get resource : "counters", id : opts.id, query : opts.query

  acl : ( opts ) ->
    get resource : "counters", id : opts.id
    .then ( res ) ->
      counter = res.data.counters[ 0 ]
      return counter unless opts.user
      c = { acl : _.clone( counter.acl ) }
      c.acl[ opts.user ] = opts.level
      put resource : "counters", id : opts.id, data : c

  users : ( opts ) ->
    options = { resource : 'users' }
    if opts.id?
      options.id = opts.id
    else
      if opts.username
        options.query = { where : { username : opts.username } }
    console.log options
    get options