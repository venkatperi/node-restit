process.on("uncaughtException", function(err) {
  return console.log(err.message);
});

require('./lib/cli');
