var exports, prettyjson, write;

prettyjson = require('prettyjson');

write = function(res, opts) {
  var str;
  if (opts == null) {
    opts = {};
  }
  if (res == null) {
    return;
  }
  if (typeof res === "string") {
    console.log(res);
  } else {
    str = opts["nopretty"] ? JSON.stringify(res) : prettyjson.render(res);
    console.log(str);
  }
  return res;
};

module.exports = exports = write;
