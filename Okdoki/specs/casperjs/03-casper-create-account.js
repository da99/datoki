//
// === Creating an account
//


var base_funcs = require("/home/da/imp/MyLife/apps/SITES/okdoki/test/casper_base");
var exists_f   = base_funcs.create_exists;
var test_f     = base_funcs.create_test;
var casper     = base_funcs.new_casper();
var base_url   = 'http://localhost:' + casper.cli.args[0];
var phrase     = 'Hoppe gives us hope';
var contact    = "someone@miniuni.zbc";
var screen_name= "go999";


// === Make sure frontpage is working.
//
casper.start(base_url + '/', function () {
  this.test.assertHttpStatus(200);
});

casper.then(function () {

  // === see if errors are displayed.
  var form = 'form#form_create_account';
  var div_errors = form + ' div.errors';
  this.fill(form, {
    'screen_name': '',
    'pass_phrase': '',
    'confirm_pass_phrase': '',
    'email': contact
  }, false);

  this.click(form + ' button.submit');

  this.waitFor(function check() {
    return this.exists(div_errors);
  }, function then() {
    this.test.assertExists(div_errors, div_errors + ' in form exist.');
  });

});

// === see if screen name errors are displayed
casper.then(function () {

  var form = 'form#form_create_account';
  var div_errors = form + ' div.errors';

  // === see if screen name errors are displayed.
  this.fill(form, {
    'screen_name'        : '',
    'pass_phrase'         : phrase,
    'confirm_pass_phrase' : phrase,
    'email'              : contact
  }, false);

  this.click(form + ' button.submit');

  this.waitFor(function check() {
    return this.exists(div_errors);
  }, function then() {
    this.test.assertEqual(this.fetchText(div_errors), "Name, \"\", must be 3-15 chars: 0-9 a-z A-Z _ - .", " Screen name errors when creating account. ");
  });

});

// === see if pass_phrase errors are displayed
casper.then(function () {

  var form = 'form#form_create_account';
  var div_errors = form + ' div.errors';

  this.fill(form, {
    'screen_name'        : screen_name,
    'pass_phrase'         : "",
    'confirm_pass_phrase' : "",
    'email'              : contact
  }, false);

  this.click(form + ' button.submit');

  this.waitFor(function check() {
    return this.exists(div_errors);
  }, function then() {
    this.test.assertEqual(this.fetchText(div_errors), "Pass phrase must be at least 9 chars long.", " Pass phrase errors when creating account. ");
  });

});

// === see if pass_phrase confirm errors are displayed
casper.then(function () {

  var form = 'form#form_create_account';
  var div_errors = form + ' div.errors';

  this.fill(form, {
    'screen_name'        : screen_name,
    'pass_phrase'         : phrase,
    'confirm_pass_phrase' : phrase + "u",
    'email'              : contact
  }, false);

  this.click(form + ' button.submit');

  this.waitFor(function check() {
    return this.exists(div_errors);
  }, function then() {
    this.test.assertEqual(this.fetchText(div_errors), "Pass phrase confirmation does not match pass phrase.", " Pass phrase confirm errors when creating account. ");
  });

});

// === Email is optional for creating an account.
casper.then(function () {

  var form = 'form#form_create_account';
  var div_errors = form + ' div.errors';

  this.fill(form, {
    'screen_name'        : screen_name,
    'pass_phrase'         : phrase,
    'confirm_pass_phrase' : phrase,
    'email'              : ""
  }, false);

  this.click(form + ' button.submit');

  this.waitFor(function check() {
    return this.exists("#homepages");
  }, function then() {
    this.test.assertTextExists("Welcome, " + screen_name, " Email optional when creating account. ");
  });

});


casper.run(function () {
  this.test.renderResults(true);
});



