_ = require 'underscore'
api = require './api/versionr-api'
write = require './write'
conf = require './conf'
rl = require 'readline-sync'
color = require './color'
cache = require './cache'
Q = require 'q'
users = require './users'

Me = conf.get "user"

module.exports = exports =

  signup : require './commands/signup'
  login : require './commands/login'
  logout : require './commands/logout'
  validate : require './commands/validate'

  users : ( opts ) ->
    api.users opts
    .then ( data ) -> write data
    .fail ( err ) -> write err

  counters : ( opts ) ->
    api.counters opts
    .then ( res ) ->
      promises = []
      for c in res.data.counters
        for own uid, level of c.acl
          promises.push users.get( id : uid ) unless uid == Me.objectId

      return write( res ) unless promises.length

      Q.all( promises ).then ( res2 ) ->
        res.data.users ?= []
        for u in res2[ 0 ].data.users
          res.data.users.push u
        write res
    .fail ( err ) -> write err

  incCounter : ( opts ) ->
    data =
      id : opts.id
    counter = conf.get "counters:#{opts.id}"
    data.step = opts.step if counter.type is "int"
    data.step = opts.release if counter.type is "semver"

    api.inc data
    .then ( data ) -> write data, { onlyValue : true }
    .fail ( err ) -> write err

  counterAccess : ( opts ) ->
    api.acl opts
    .then ( data ) -> write data
    .fail ( err ) ->
      console.log err
      write err