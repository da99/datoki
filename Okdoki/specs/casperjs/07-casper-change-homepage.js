
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


var form                = '#form_update_about ';
var fields              = form + 'div.fields';
var textarea            = form + 'textarea';
var success             = form + 'div.success';
var submit              = form + 'button.submit';
var show_fields         = form + 'button.show';
var show_again          = form + 'button.show_again';
var show_again_div      = form + 'div.show_again';
var success             = form + 'div.success';

var css_specify_display = function (form) { return $(form + 'div.specify').css('display'); };
var css_display         = function (selector) { return $(selector).css('display'); };
var css_submit_display  = function (form) { return $(form + 'button.submit').css('display'); };
var css_fields_display  = function (form) { return $(form + 'div.fields').css('display'); };
var css_menu_selected   = function () { return $('#form_homepage_priv select option:selected').val(); };
var css_body            = function (css) { return $('body').hasClass(css); };

var about_1             = 'This is about 1.';
var about_2             = 'This is about 2.';
var success_msg         = 'Your "About Me" section has been updated.';

// === Default css classes.
casper.thenOpen(base_funcs.url + '/info/go99', function () {
  this.test.assertEvalEquals(css_display, 'none', "Update about fields: hidden by default.", fields);
  this.test.assertEvalEquals(css_display, 'none', "Show again: hidden by default.", form + 'div.show_again');
});

// === Show "update about" form.
casper.then(function () {
  this.click(show_fields);
  this.test.assertEvalEquals(css_display, 'block', "Update about: shown by clicking show button.", fields);
  this.test.assertEvalEquals(css_display, 'none', "Show form msg: hidden by clicking show button.", form + 'div.show');
});

// === Update about.
casper.then(function () {
  this.fill(form, {
    about: about_1
  });
  this.click(submit);
  this.waitForSelector(success, function () {
    this.test.assertEqual(this.fetchText(success), success_msg, 'Update "about" success message.');
    this.test.assertEvalEquals(css_display, 'none', 'Form fields hidden during success msg.', fields);
    this.test.assertEvalEquals(css_display, 'block', '"Show again": displayed during success msg.', show_again_div);
  });
});

// === Update again.
casper.then(function () {
  this.click(show_again);
  this.test.assertEvalEquals(css_display, 'block', 'About form displayed after clicking show_again.', form);
  this.test.assertEvalEquals(function (form) { return $(form + ' div.success').length;}, 0, 'Success msg: removed after clicking show_again.', form);
  this.fill(form, {
    about: about_2
  });
  this.click(submit);
  this.waitForSelector(success, function () {
    this.test.assertEqual(this.fetchText(success), success_msg, 'Update "about" success message.');
  });
});

// === Make sure edit is permanent.
casper.then(function () {
  this.reload(function () {
    this.test.assertEqual(this.fetchText(textarea), about_2, 'About section permanently saved.');
  });
});

casper.run(function () {
  this.test.renderResults(true);
});


