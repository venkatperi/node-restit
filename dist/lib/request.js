var Headers, Q, Request, Rest, conf, cson, error, exports, helpers, httpStatus, jpath, mediaType, parseCson, path, request, safeParse, t, write, _,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

conf = require('./conf');

Rest = require('restler');

_ = require('underscore');

Q = require('q');

write = require('./write');

httpStatus = require('http-status');

error = require('./error');

Headers = require('./headers');

t = require('exectimer');

mediaType = require('media-type');

jpath = require("JSONpath");

cson = require('cson');

parseCson = function(str) {
  var d;
  d = Q.defer();
  cson.parse(str, function(err, obj) {
    if (err != null) {
      return d.reject(err);
    }
    return d.resolve(obj);
  });
  return d.promise;
};

safeParse = function(data) {
  var e;
  if (data == null) {
    return;
  }
  try {
    if (typeof data === "string") {
      data = JSON.parse(data);
    }
  } catch (_error) {
    e = _error;
  }
  return data;
};

path = function(r, id) {
  if (id != null) {
    return "/r/" + id;
  } else {
    return "/" + r;
  }
};

helpers = "base64 = (str) -> new Buffer(str).toString('base64')";

Request = (function() {
  Request.prototype.options = {
    headers: {},
    query: {},
    data: {},
    method: "get"
  };

  Request.prototype.url = null;

  function Request(opts) {
    this.send = __bind(this.send, this);
    var apiConfig, apiName, promise;
    apiName = opts.api || conf.get("api:default");
    if (apiName == null) {
      throw error("API name missing");
    }
    apiConfig = conf.get("api:" + apiName);
    if (apiConfig == null) {
      throw error("API not found in config");
    }
    this.options.method = opts.op || (function() {
      throw "no op";
    })();
    if (opts.where != null) {
      this.options.query.where = opts.where;
    }
    this.url = "" + apiConfig.url + (path(opts.resource, opts.id));
    promise = Q();
    if (opts.query != null) {
      promise = promise.then((function(_this) {
        return function() {
          return parseCson(opts.query);
        };
      })(this)).then((function(_this) {
        return function(obj) {
          return _this.options.query = obj;
        };
      })(this));
    }
    if (opts.data != null) {
      promise = promise.then((function(_this) {
        return function() {
          return parseCson(opts.data);
        };
      })(this)).then((function(_this) {
        return function(obj) {
          return _this.options.data = obj;
        };
      })(this));
    }
    this.promise = promise.then((function(_this) {
      return function() {
        var mt;
        Headers(_this.options.headers, apiConfig.headers);
        Headers(_this.options.headers, opts.header);
        if (_.isEmpty(_this.options.data)) {
          delete _this.options.data;
        } else if (!opts["nojson"] && (_this.options.headers['Content-Type'] == null)) {
          _this.options.headers["Content-Type"] = "application/json";
        }
        if (_this.options.headers['Content-Type'] != null) {
          mt = mediaType.fromString(_this.options.headers["Content-Type"]);
          if (!mt.isValid()) {
            return Q.reject({
              error: {
                message: "Bad media type"
              }
            });
          }
          if (mt.type === "application" && mt.subtype === "json") {
            _this.options.data = JSON.stringify(_this.options.data);
          }
        }
        if (_.isEmpty(_this.options.headers)) {
          delete _this.options.headers;
        }
        if (_.isEmpty(_this.options.query)) {
          delete _this.options.query;
        }
        if (opts.verbose) {
          write({
            apiName: apiName,
            config: apiConfig
          });
          write({
            request: {
              url: _this.url,
              options: _this.options
            }
          }, opts);
          return write("");
        }
      };
    })(this));
    this.promise.done();
  }

  Request.prototype.send = function() {
    return this.promise.then((function(_this) {
      return function() {
        var d, tick;
        d = Q.defer();
        tick = new t.Tick("request");
        tick.start();
        Rest.request(_this.url, _this.options).on('success', function(data, res) {
          return d.resolve([safeParse(data), res]);
        }).on('error', function(err, res) {
          return d.reject(err);
        }).on('timeout', function(ms) {
          return d.reject({
            message: "timeout " + ms,
            statusCode: 408
          });
        }).on('fail', function(data, res) {
          return d.reject([safeParse(data), res]);
        });
        return d.promise.then(function(x) {
          tick.stop();
          x.push(t.timers.request);
          return x;
        }).fail(function(x) {
          tick.stop();
          x.push(t.timers.request);
          return x;
        });
      };
    })(this));
  };

  return Request;

})();

request = function(opts) {
  var err;
  try {
    request = new Request(opts);
    if (opts.nosend) {
      return Q([
        "didn't send request (--nosend was specified)", {
          statusCode: 200
        }
      ]);
    } else {
      return request.send();
    }
  } catch (_error) {
    err = _error;
    return Q.reject([err]);
  }
};

module.exports = exports = function(cmd) {
  return function(opts) {
    opts.op = cmd;
    return request(opts).then(function(_arg) {
      var code, data, duration, res, timer;
      data = _arg[0], res = _arg[1], timer = _arg[2];
      code = httpStatus[res.statusCode].toUpperCase();
      duration = timer != null ? timer.duration() / 1000000 : 0;
      if (!opts["noinfo"]) {
        write("> HTTP " + res.statusCode + " " + code + ", " + duration + " ms.");
      }
      if (opts.jpath != null) {
        data = jpath["eval"](data, opts.jpath);
        if (_.isArray(data) && data.length === 1) {
          data = data[0];
        }
      }
      return write(data, opts);
    }).fail(function(_arg) {
      var code, err, res, timer;
      err = _arg[0], res = _arg[1], timer = _arg[2];
      if ((err != null) && (timer != null)) {
        code = httpStatus[res.statusCode].toUpperCase();
        if (!opts["noinfo"]) {
          write("> HTTP " + res.statusCode + " " + code + ", " + (timer.duration() / 1000000) + " ms.");
        }
      }
      return write(err, opts);
    });
  };
};
