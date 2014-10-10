_ = require 'underscore'
conf = require './conf'
write = require './write'
error = require './error'
Q = require 'q'
headers = require './headers'

setConfig = ( opts ) ->
  try
    throw error "API name missing" unless opts.api?
    throw error "API name can't be 'default'" if opts.api is 'default'

    apiName = "api:#{opts.api}"
    config = conf.get( apiName ) or {}

    if opts.header?
      config.headers ?= {}
      headers config.headers, opts.header

    config.url = opts.url if opts.url?
    conf.set apiName, config
    .then ( res ) ->
      return Q( res ) unless opts.default
      conf.set "api:default", opts.api
    .fail ( err ) -> throw err
    .done()
  catch err
    write err

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
