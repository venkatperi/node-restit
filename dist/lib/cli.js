var cmd, cmdOptions, configApi, parser, request, _i, _len, _ref;

parser = require('nomnom');

request = require('./request');

configApi = require('./configureApi');

parser.script("restit");

cmdOptions = function(cmd, name) {
  return cmd.option("api", {
    abbr: 'a',
    help: "the API (from config). if missing, default api is used."
  }).option("resource", {
    abbr: 'r',
    position: 1,
    "default": "",
    help: "resource part of the URL (baseurl/resource). Defaults to empty string"
  }).option('data', {
    abbr: 'd',
    required: false,
    help: "request body"
  }).option('query', {
    abbr: 'q',
    required: false,
    help: "query parameters"
  }).option("header", {
    abbr: 'e',
    list: true,
    help: "request header(s). can be used more than once. empty value deletes header."
  }).option("nopretty", {
    flag: true,
    help: "don't run output through prettyjson"
  }).option("verbose", {
    abbr: 'v',
    flag: true,
    help: "verbose output"
  }).option("nojson", {
    flag: true,
    help: "don't encode body as 'application/json'. uses 'application/x-www-form-urlencoded'"
  }).option("nosend", {
    flag: true,
    help: "construct the request but don't send it"
  }).option("noinfo", {
    flag: true,
    help: "no informational output"
  }).option("jpath", {
    help: "json path selector (transform JSON response)"
  }).callback(request(name)).help("Send '" + name + "' REST command");
};

_ref = ['get', 'put', 'post', 'delete'];
for (_i = 0, _len = _ref.length; _i < _len; _i++) {
  cmd = _ref[_i];
  cmdOptions(parser.command(cmd), cmd);
}

parser.command("set-config").option("api", {
  position: 1,
  required: true,
  help: "name of the API"
}).option("url", {
  abbr: 'u',
  help: "base url of the API"
}).option("header", {
  abbr: 'e',
  list: true,
  help: "add/remove request headers (leave value empty to remove)"
}).option("default", {
  abbr: 'd',
  flag: true,
  help: "make this the default API"
}).callback(configApi.set);

parser.command("show-config").option("api", {
  position: 1,
  help: "Name of the API"
}).callback(configApi.show);

parser.parse();
