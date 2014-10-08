versions = require './pkginfo'
color = require './color'
pkginfo = require './pkginfo'

header = [
  "Welcome to #{color.dark( 'Versionr' )}"
  "node #{process.versions.node}, versionr-cli: #{pkginfo.version}"
]

module.exports = exports = header.join( "\n" )

