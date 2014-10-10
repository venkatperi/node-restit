_ = require 'underscore'
module.exports = exports = ( source, headers ) ->
  return unless source? and headers?

  headers = [ headers ] if typeof headers is "string"

  if _.isArray headers
    for h in headers
      console.log h
      throw error ("Bad header format '#{h}'") unless h.indexOf( ":" ) > 0
      [name, value] = h.split ":"
      if value.length == 0
        delete source[ name ] if source[ name ]
      else
        source[ name ] = value
  else if _.isObject headers
    _.extend source, headers if _.isObject headers
  source
