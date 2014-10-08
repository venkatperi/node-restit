_ = require 'underscore'
color = require './color'
conf = require './conf'
printf = require "printf"
prettyjson = require 'prettyjson'


user = conf.get 'user'

counterDetails = ( counter, users ) ->
  obj =
    id : counter.objectId
    type : counter.type
    value : counter.value
    name : counter.name
    description : counter.description

  access = {}
  for own u,v of counter.acl
    name = if u == user.objectId then 'me'
    if users?
      for x in users
        name = x.username if x.objectId == u
        break
    access[ name or u ] = v
  obj.access = access

  prettyjson.render obj


formatCounter = ( counter, opts = {}, users ) ->
  access = counter.acl[ user.objectId ]

  if opts.line
    return printf "%5s %10s  %-8s %-15s", access, counter.objectId, counter.value, counter.name

  return counterDetails( counter, users ) if opts.detail

  if opts.onlyValue
    return counter.value

formatCounters = ( counters, opts, users ) ->
  return unless counters?
  return if opts.outputs? and "counters" not in opts.outputs

  unless opts.onlyValue
    _.extend opts, if counters.length == 1 then { detail : true } else { line : true }

  lines = []
  for r in counters
    lines.push formatCounter r, opts, users
  lines.join "\n"

formatUser = ( user, opts = {} ) ->
  return printf "%10s  %-15s", user.objectId, user.username

formatUsers = ( users, opts ) ->
  return unless users?
  return if opts.outputs? and "users" not in opts.outputs

  lines = []
  for r in users
    lines.push formatUser r, opts
  lines.join "\n"

write = ( res, opts = {} ) ->
  return unless res?

  lines = []
  if typeof res is "string"
    lines.push res
  else
    lines.push formatCounters( res.data.counters, opts, res.data.users )
    lines.push formatUsers( res.data.users, opts )

    unless opts.noMessage or opts.onlyValue or res.status.statusCode < 400
      msg = "#{res.status.message} " if res.status.message.length
      [col, result] = if res.status.statusCode >= 400 then [ color.error, "error" ] else [ color.success,
                                                                                           "ok" ]
      code = col "[#{res.status.statusCode}] #{result}"
      msg += code
      lines.push msg

  console.log lines.join( '\n' )
  res

module.exports = exports = write