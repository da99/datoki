//
// === Sign-ing in
//


var base_funcs = require("/home/da/imp/MyLife/apps/SITES/okdoki/test/casper_base");
var exists_f   = base_funcs.create_exists;
var test_f     = base_funcs.create_test;
var innerHTML_f= base_funcs.innerHTML_f;
var base_url   = 'http://localhost:5001';
var casper     = base_funcs.new_casper("sign_in");


var msg = function () {
  return document.querySelector('#sign_in div.errors').innerHTML;
};


// === Screen name is required.
//
casper.then(function () {
  var form  = 'form#form_create_screen_name';
  var button= form + ' button.submit';
  var errors= form + ' div.errors';

  this.fill(form, {
    'screen_name': ''
  }, false);

  this.click(button);

  var test_func = test_f('assertEvalEquals', innerHTML_f(errors), "Name, \"\", must be 3-15 chars: 0-9 a-z A-Z _ - .", "Msg shown: Screen name is required.");
  this.waitFor(exists_f(errors), test_func, null, 1000);
});

// === Screen name is not unique.
//
casper.then(function () {
  var form  = 'form#form_create_screen_name';
  var button= form + ' button.submit';
  var errors= form + ' div.errors';

  this.fill(form, {
    'screen_name': 'go99'
  }, false);

  this.click(button);

  var test_func = test_f('assertEvalEquals', innerHTML_f(errors), "Screen name already exists: go99", "Msg shown: Screen name already taken.");
  this.waitFor(exists_f(errors), test_func, null, 1000);
});

// === Success
//
casper.then(function () {
  var form  = 'form#form_create_screen_name';
  var button= form + ' button.submit';
  var success= form + ' div.success';

  this.fill(form, {
    'screen_name': 'go991'
  }, false);

  this.click(button);

  this.waitFor(
    function () { return this.getCurrentUrl().match(/info/); }, 
    function () {
      this.test.assertEqual(this.getCurrentUrl(), "http://localhost:5001/info/go991/", 'New homepage loaded: /info/go991/');
    }
  );
});


casper.run(function () {
  this.test.renderResults(true);
});


