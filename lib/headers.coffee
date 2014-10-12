_ = require 'underscore'

capitalize = ( str ) -> str.charAt( 0 ).toUpperCase() + str.substr( 1 ).toLowerCase()

normalizeName = ( name ) ->
  return unless name?
  name = name.trim()
  parts = name.split "-"
  output = for part in parts
    capitalize part
  output.join "-"


module.exports = exports = ( source, headers ) ->
  return unless source? and headers?

  headers = [ headers ] if typeof headers is "string"

  if _.isArray headers
    for h in headers
      throw error ("Bad header format '#{h}'") unless h.indexOf( ":" ) > 0
      [name, value] = h.split ":"
      name = normalizeName name
      value = value.trim()
      if value.length == 0
        delete source[ name ] if source[ name ]
      else
        source[ name ] = value
  else if _.isObject headers
    for own k,v of headers
      source[ normalizeName k ] = v

  source
