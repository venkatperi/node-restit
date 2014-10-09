_ = require 'underscore'
color = require './color'
conf = require './conf'
printf = require "printf"
prettyjson = require 'prettyjson'

write = ( res, opts = {} ) ->
  return unless res?

  if typeof res is "string"
    console.log res
  else
    console.log prettyjson.render res

  res

module.exports = exports = write