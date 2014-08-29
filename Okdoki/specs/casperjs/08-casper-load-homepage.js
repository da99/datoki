
//
// === Load records for homepage: q&a, cheers/boos, etc
//

var base_funcs = require("/home/da/imp/MyLife/apps/SITES/okdoki/test/casper_base");
var exists_f   = base_funcs.create_exists;
var test_f     = base_funcs.create_test;
var innerHTML_f= base_funcs.innerHTML_f;
var casper     = base_funcs.new_casper();

casper.start(base_funcs.url + '/info/go99')

function body(s) { return s + " div.body "; }
function no_rows(s) { return body(s) + " div.no_rows "; }
function loading(s) { return body(s) + " div.loading ";}

function css_count(s) {
  return $(s).length;
}

// === No records message shown.
casper.then(function () {
  var temp = '#qa';
  this.waitForSelector(temp, function () {
    this.test.assertSelectorExists(no_rows(temp), no_rows(temp) + " exists.");
    this.test.assertEvalEquals(css_count, 0, loading(temp) + " does not exists.", loading(temp) );
  });
});

casper.then(function () {
  var temp = '#boos';
  this.waitForSelector(temp, function () {
    this.test.assertSelectorExists(no_rows(temp), no_rows(temp) + " exists.");
    this.test.assertEvalEquals(css_count, 0, loading(temp) + " does not exists.", loading(temp) );
  });
});

casper.then(function () {
  var temp = '#latest';
  this.waitForSelector(temp, function () {
    this.test.assertSelectorExists(no_rows(temp), no_rows(temp) + " exists.");
    this.test.assertEvalEquals(css_count, 0, loading(temp) + " does not exists.", loading(temp) );
  });
});


casper.run(function () {
  this.test.renderResults(true);
});
