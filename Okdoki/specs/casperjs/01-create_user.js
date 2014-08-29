var helper = require('./helper');
var assert = require('assert');
var _      = require('underscore');

describe( 'it runs', function () {
  beforeEach(function (done) {
    helper.new(done);
  });

  afterEach(function (done) {
    helper.destroy(done);
  });

  it( 'runs', function (done) {
    helper.done = done;

    var lines  = [];
    var spooky = helper.spooky;

    spooky.start( 'http://en.wikipedia.org/wiki/Spooky_the_Tuff_Little_Ghost');

    spooky.then(function () {
      this.echo("test it")
      this.echo(this.getTitle());
    });

    helper.on_console(done, function (line) {
      assert.equal(line, "Spooky the Tuff Little Ghost - Wikipedia, the free encyclopedia");
    });

    spooky.run();
  });
}); // === describe



