process.on "uncaughtException", ( err ) ->
  console.log err.message

require './lib/cli'
