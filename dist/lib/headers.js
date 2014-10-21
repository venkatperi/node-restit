var capitalize, exports, normalizeName, _,
  __hasProp = {}.hasOwnProperty;

_ = require('underscore');

capitalize = function(str) {
  return str.charAt(0).toUpperCase() + str.substr(1).toLowerCase();
};

normalizeName = function(name) {
  var output, part, parts;
  if (name == null) {
    return;
  }
  name = name.trim();
  parts = name.split("-");
  output = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = parts.length; _i < _len; _i++) {
      part = parts[_i];
      _results.push(capitalize(part));
    }
    return _results;
  })();
  return output.join("-");
};

module.exports = exports = function(source, headers) {
  var h, k, name, v, value, _i, _len, _ref;
  if (!((source != null) && (headers != null))) {
    return;
  }
  if (typeof headers === "string") {
    headers = [headers];
  }
  if (_.isArray(headers)) {
    for (_i = 0, _len = headers.length; _i < _len; _i++) {
      h = headers[_i];
      if (!(h.indexOf(":") > 0)) {
        throw error("Bad header format '" + h + "'");
      }
      _ref = h.split(":"), name = _ref[0], value = _ref[1];
      name = normalizeName(name);
      value = value.trim();
      if (value.length === 0) {
        if (source[name]) {
          delete source[name];
        }
      } else {
        source[name] = value;
      }
    }
  } else if (_.isObject(headers)) {
    for (k in headers) {
      if (!__hasProp.call(headers, k)) continue;
      v = headers[k];
      source[normalizeName(k)] = v;
    }
  }
  return source;
};
