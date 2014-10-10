_ = require 'underscore'
parser = require( 'nomnom' )
conf = require './conf'
request = require './request'
configApi = require './configureApi'

cmdOptions = ( cmd, name ) ->
  cmd
  .option "api",
    abbr : 'a'
    help : "Name of the API (from config)"

  .option "resource",
    abbr : 'r'
    required : true
    help : "Name of the REST resource"

  .option 'id',
    abbr : 'i'
    required : false
    help : "Instance ID"

  .option 'data',
    abbr : 'd'
    required : false
    help : "request body"

  .option 'query',
    abbr : 'q'
    required : false
    help : "query"

  .option 'where',
    abbr : 'w'
    required : false
    help : "'where' query filter"

  .option "header",
    abbr : 'e'
    list : true
    help : "Request headers"

  .option "verbose",
    abbr : 'v'
    flag : true
    help : "verbose output"

  .callback request( name )

  .help "Send '#{name}' REST command"

for cmd in [ 'get', 'put', 'post', 'delete' ]
  cmdOptions parser.command( cmd ), cmd

parser.command "set-config"
.option "api",
  abbr : 'a'
  required : true
  help : "Name of the API"

.option "url",
  abbr : 'u'
  help : "Base URL of the API"

.option "header",
  abbr : 'e'
  list : true
  help : "Add/remove request headers"

.option "default",
  abbr : 'd'
  flag : true
  help : "Set as default API"
.callback configApi.set

parser.command "show-config"
.option "api",
  abbr : 'a'
  help : "Name of the API"
.callback configApi.show

parser.parse()
