var Q, conf, error, exports, headers, setConfig, showConfig, write, _;

_ = require('underscore');

conf = require('./conf');

write = require('./write');

error = require('./error');

Q = require('q');

headers = require('./headers');

setConfig = function(opts) {
  var apiName, config, err;
  try {
    if (opts.api == null) {
      throw error("API name missing");
    }
    if (opts.api === 'default') {
      throw error("API name can't be 'default'");
    }
    apiName = "api:" + opts.api;
    config = conf.get(apiName) || {};
    if (opts.header != null) {
      if (config.headers == null) {
        config.headers = {};
      }
      headers(config.headers, opts.header);
    }
    if (opts.url != null) {
      config.url = opts.url;
    }
    return conf.set(apiName, config).then(function(res) {
      if (!opts["default"]) {
        return Q(res);
      }
      return conf.set("api:default", opts.api);
    }).fail(function(err) {
      throw err;
    }).done();
  } catch (_error) {
    err = _error;
    return write(err);
  }
};

showConfig = function(opts) {
  var config, name;
  name = opts.api ? "api:" + opts.api : "api";
  config = conf.get(name);
  if (config != null) {
    return write(config);
  } else {
    return write("No such API");
  }
};

module.exports = exports = {
  set: setConfig,
  show: showConfig
};
