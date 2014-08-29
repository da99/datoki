//
// === Sign-ing in
//


var base_funcs = require("/home/da/imp/MyLife/apps/SITES/okdoki/test/casper_base");
var exists_f   = base_funcs.create_exists;
var test_f     = base_funcs.create_test;
var innerHTML_f= base_funcs.innerHTML_f;
var casper     = base_funcs.new_casper("sign_in");


var msg = function () {
  return document.querySelector('#sign_in div.errors').innerHTML;
};


var form          = '#form_trash_screen_name ';
var success       = form + 'div.success';
var success_msg   = "Screen name, go99, has been put in trash." +
  " You have 2 days from now to change your mind before it gets completely deleted.";
var unsuccess_msg = "Screen name, go99, has been taken out of the trash.";
var css_submit   = function (form) { return $(form + 'button.submit').css('display'); };
var css_display  = function (s) { return $(s).css('display'); };
var css          = function (s) { return $(s[0]).hasClass(s[1]); };


// === Default css classes.
casper.thenOpen(base_funcs.url + '/info/go99', function () {
  this.test.assertEvalEquals(css, false, "Form has no class: trashed.", [form, 'trashed']);
  this.test.assertEvalEquals(css_submit, 'inline-block', 'Delete button shown when not trashed.', form);
  this.test.assertEvalEquals(css_display, 'none', 'Undo: hidden by default.', form + 'div.undo');

  this.click(form + 'button.submit');

  this.waitForSelector(success, function () {
    this.test.assertEvalEquals(css, true, "Form has class: trashed.", [form, 'trashed']);
    this.test.assertEquals(this.fetchText(success), success_msg, "Msg: Time until complete deletion.");
    this.test.assertEvalEquals(css_display, 'none', 'Form fields: hidden.', form + 'div.fields');
    this.test.assertEvalEquals(css_display, 'block', 'Undo button: displayed.', form + 'div.undo');
  }, null, 1000);
});


// === Non-authorized customers get 404
casper.then_log_out();
casper.ignore_404 = true;
casper.thenOpen(base_funcs.url + '/info/go99', function () {
  this.test.assertHttpStatus(404);
  this.test.assertEquals(this.fetchText('body').indexOf('Screen name not found:') > -1, true);
  this.ignore_404 = false;
});
casper.then_log_in();


casper.thenOpen(base_funcs.url + '/info/go99', function () {

  this.test.assertEvalEquals(css_display, 'block', 'Undo: shown for trashed screen name.', form + 'div.undo');
  this.test.assertEvalEquals(css, true, "Form has class: trashed.", [form, 'trashed']);
  this.test.assertEquals( this.fetchText(success), success_msg, "Delete/un-delete message shown on page reload.");
  this.test.assertEvalEquals(css_display, 'none',  'Form fields: hidden.',    form + 'div.fields');
  this.test.assertEvalEquals(css_display, 'block', 'Undo button: displayed.', form + 'div.undo');

});

casper.then(function () {
  this.click(form + 'button.undo');

  this.wait(200);

  this.waitForSelector(success, function () {
    this.test.assertEquals( this.fetchText(success), unsuccess_msg, "Undo deletion success msg shown.");
    this.test.assertEvalEquals(css_display, 'block', 'Form fields: displayed.', form + 'div.fields');
    this.test.assertEvalEquals(css_display, 'none', 'Undo button: hidden.', form + 'div.undo');
  });
});

casper.run(function () {
  this.test.renderResults(true);
});


