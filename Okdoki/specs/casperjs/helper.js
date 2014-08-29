var Spooky = require('spooky');
var _      = require('underscore');


module.exports.new = function (done) {
  var spooky = module.exports.spooky = new Spooky({
    casper: {
      logLevel: 'debug',
      verbose: true
    }
  }, function (err) {
    if (err) {
      e = new Error('Failed to initialize SpookyJS');
      e.details = err;
      throw e;
    }

    spooky.on('error', function (e) {
      console.error(e);
    });

    /*
    // Uncomment this block to see all of the things Casper has to say.
    // There are a lot.
    // He has opinions.
    spooky.on('console', function (line) {
    console.log(line);
    });
    */

    spooky.on('log', function (log) {
      if (log.space === 'remote') {
        console.log(log.message.replace(/ \- .*/, ''));
      }
    });

    done();
  });
};

module.exports.on_console = function (done, func) {
  var lines = [];
  this.spooky.on('console', function (line) {
    if (_.last(lines) === 'test it') {
      func(line);
      done();
    }
    lines.push(line);
  });
};

module.exports.destroy = function (done) {
  if (module.exports.spooky) {
    module.exports.spooky.removeAllListeners();
    module.exports.spooky.destroy();
    done();
  }
};
