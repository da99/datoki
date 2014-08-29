
var base_url = exports.url = 'http://localhost:5001';

// http://roguejs.com/2011-11-30/console-colors-in-node-js/
var red_c, blue_c, reset;
red_c   = '\u001b[31m';
blue_c  = '\u001b[34m';
reset   = '\u001b[0m';

function red(msg) {
  return red_c + msg + reset;
}

exports.create_exists = function ( s ) {
  return function () {
    return this.exists(s);
  };
};

exports.create_test   = function test() {
  var type = arguments[0];
  var args = [];
  var l = arguments.length;
  var i = 1;
  while (i < l) {
    args.push(arguments[i]);
    i++;
  };
  return function () {
    this.test[type].apply(this.test, args);
  };
};

exports.new_casper = function (sign_in) {
  var opts = {
    verbose: false,
    logLevel: "info",
    onError: function (self, m) {
      console.log('Exiting because of this error: ' + m);
      self.exit();
    }
  };

  var casper = require('casper').create(opts);
  exports.prepare(casper);

  if (sign_in) {
    casper.start(base_url + '/')
    casper.waitForSelector('title', function () {
      this.test.assertHttpStatus(200);
      var sign_in = 'form#form_sign_in';

      this.fill(sign_in, {
        'screen_name': 'go99',
        'pass_phrase': "Pass phrase",
      }, false);
      this.click(sign_in + ' button.submit');
      this.waitFor(exists_f('#homepages'), null, null, 1000);
    }, null, 4000);
  }

  return casper;
}

exports.innerHTML_f = function (s) {
  return new Function("return document.querySelector(\"" + s + "\").innerHTML;");
};

exports.prepare = function (casper) {
  casper.then_log_out = function () {
    this.thenOpen(base_funcs.url + '/log-out');
  };

  casper.then_log_in = function (name) {
    if (!name)
      name = 'go99';
    this.thenOpen(base_url + '/', function () {
      this.waitForSelector('title', function () {
        this.test.assertHttpStatus(200);
        var sign_in = 'form#form_sign_in';

        this.fill(sign_in, {
          'screen_name' : name,
          'pass_phrase'  : "Pass phrase",
        }, false);
        this.click(sign_in + ' button.submit');
        this.waitFor(exists_f('#homepages'), null, null, 1000);
      }, null, 4000);
    });
  };

  casper.on('error', function(msg, trace) {
    this.echo(red( + 'JS error: ' + msg));
    this.echo('Exiting...');
    this.exit(1);
  });

  casper.on('page.error', function(msg, trace) {
    this.echo(red( 'JS page error: ' + msg ));
    this.echo('Exiting...');
    this.exit(1);
  });

  casper.on('http.status.404', function(resource) {
    if (this.ignore_404)
      return false;
    this.echo(red( '404: ' + resource.url));
    this.echo('Exiting...');
    this.exit(1);
  });

  casper.on('http.status.500', function(resource) {
    this.echo(red('500 error: ' + resource.url));
    this.echo('Exiting...');
    this.exit(1);
  });

  casper.on('http.status.501', function(resource) {
    this.echo(red( '501 error: ' + resource.url));
    this.echo('Exiting...');
    this.exit(1);
  });

  casper.on('http.status.503', function(resource) {
    this.echo(red( 'woops, 503 error: ' + resource.url) );
    this.echo('Exiting...');
    this.exit(1);
  });

}

