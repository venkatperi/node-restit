prettyjson = require 'prettyjson'

write = ( res, opts = {} ) ->
  return unless res?

  if typeof res is "string"
    console.log res
  else
    str = if opts[ "nopretty" ] then JSON.stringify res else prettyjson.render( res )
    console.log str

  res

module.exports = exports = write