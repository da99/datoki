
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

casper.then_log_in('dos');

casper.thenOpen(base_funcs.url + '/info/go99');

// === Add question.
var q        = 'Why is Singapore wealthier than Indonesia and Malaysia?';
var q_form   = '#form_create_question';
var q_record = '#qa div.body div.record';

casper.then(function () {
  this.fill(q_form, {
    q: q
  }, false);

  this.click(q_form + ' button.submit');

  this.waitForSelector(q_record, function () {
    this.test.assertEquals(this.fetchText(q_record).indexOf(q) > 0, true, "Question is added to homepage.");
  });
});

// === Add cheer.
casper.then(function () {
});

// === Add jeer.
casper.then(function () {
});


casper.run(function () {
  this.test.renderResults(true);
});
