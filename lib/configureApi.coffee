_ = require 'underscore'
conf = require './conf'
write = require './write'

setConfig = ( opts ) ->
  throw new Error "API name missing" unless opts.api?
  apiName = "api:#{opts.api}"
  config = conf.get( apiName ) or {}

  if opts.header?
    config.headers ?= {}
    headers = if _.isArray opts.header then opt.header else [ opts.header ]
    for h in headers
      throw new Error ("Bad header format '#{h}'") unless h.indexOf( ":" ) > 0
      [name, value] = h.split ":"
      if value.length == 0
        delete config.headers[ name ]
      else
        config.headers[ name ] = value

  config.url = opts.url if opts.url?
  conf.set apiName, config
  .then ( res ) -> write "config saved"
  .fail ( err ) -> write err

showConfig = ( opts ) ->
  name = if opts.api then "api:#{opts.api}" else "api"
  config = conf.get( name )
  if config?
    write config
  else
    write "No such API"

module.exports = exports =
  set : setConfig
  show : showConfig
