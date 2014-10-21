var HOME_DIR, Q, exports, nconf;

nconf = require('nconf');

Q = require('q');

HOME_DIR = process.env.HOME;

nconf.file({
  file: "" + HOME_DIR + "/.restitconf"
});

module.exports = exports = {
  nconf: nconf,
  get: function(key) {
    return nconf.get(key);
  },
  set: function(key, value) {
    var d;
    d = Q.defer();
    nconf.set(key, value);
    nconf.save(function(err) {
      if (err != null) {
        return d.reject(err);
      }
      return d.resolve(value);
    });
    return d.promise;
  }
};
