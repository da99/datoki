//
// === Sign-ing in
//


var base_funcs = require("/home/da/imp/MyLife/apps/SITES/okdoki/test/casper_base");
var casper     = base_funcs.new_casper();
var exists_f   = base_funcs.create_exists;
var test_f     = base_funcs.create_test;
var base_url   = 'http://localhost:' + casper.cli.args[0];

var msg = function () {
  return document.querySelector('#sign_in div.errors').innerHTML;
};

casper.start(base_url + '/');

// === Screen name is requierd.
//
casper.then(function () {
  this.test.assertHttpStatus(200);
  var form = 'form#form_sign_in';
  var div_errors = form + ' div.errors';

  // ... when no screen_name is entered.
  this.click(form + ' button.submit');
  var test_func = test_f('assertEvalEquals', msg, "Screen name is required.", "Msg shown: Username is required.");
  this.waitFor( exists_f(div_errors), test_func, null, 700);

});

// === Password is required.
//
casper.then( function () {
  var sign_in = 'form#form_sign_in';
  var div_errors = sign_in + ' div.errors';

  // ... when no password is entered.
  this.fill(sign_in, {
    'screen_name': 'go99',
    'pass_phrase': "",
  }, false);
  this.click(sign_in + ' button.submit');
  var test_func = test_f( 'assertEvalEquals', msg, "Password is required.", "Msg shown: Password is required.");
  this.waitFor(exists_f(div_errors), test_func, null, 700);
});

// === Success
//
casper.then(function () {
  var sign_in = 'form#form_sign_in';

  this.fill(sign_in, {
    'screen_name': 'go99',
    'pass_phrase': "Pass_phrase",
  }, false);
  this.click(sign_in + ' button.submit');
  var test_func = test_f( 'assertEvalEquals', function () {
    return document.querySelector('#intro h2').innerHTML;
  }, "Welcome, go99.", "Msg shown: Welcome, [customer].");
  this.waitFor(exists_f('#homepages'), test_func, null, 700);
});

casper.run(function () {
  this.test.renderResults(true);
});


