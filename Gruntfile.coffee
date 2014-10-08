fs = require 'fs'

isModified = ( filepath ) ->
  now = new Date()
  modified = fs.statSync( filepath ).mtime
  return (now - modified) < 10000

module.exports = ( grunt ) ->

  grunt.initConfig
    pkg : grunt.file.readJSON "package.json"

    browserify :
      dist :
        files :
          "dist/app.js" : [ "app.coffee" ]
        options :
          transform : [ 'coffeeify', 'uglifyify' ]
          browserifyOptions :
            extensions : [ ".coffee" ]
            bundleExternal : false

    clean :
      dist : [ "dist" ]

    watch :
      dist :
        files : [ "lib/**/*.coffee", "app.coffee" ]
        tasks : [ "browserify:dist" ]


  for t in [ "uglify", "watch", "clean", "coffee" ]
    grunt.loadNpmTasks "grunt-contrib-#{t}"

  for t in [ "browserify" ]
    grunt.loadNpmTasks "grunt-#{t}"

  grunt.registerTask "dist", [
    "browserify:dist"
  ]


