// ================================================================
// ================== Helpers =====================================
// ================================================================

function form(id) {
  var e = $('#' + id);
  if (!e.length)
    throw new Error("Form #" + name + ' not found.');
  return e;
};

function click(name) {
  var e = $(name);
  if (!e.length)
    throw new Error("Link, " + name + ', not found.');
  e.click();
  return e;
}

function show_form(name) {
  return click('#forms a.' + name);
}

// ================================================================
// ================== Tests =======================================
// ================================================================


Akui.test("Sign-in form display = none", function (assert) {
  assert('none', $('#sign_in').css('display'));
});

Akui.test("create account form display = none", function (assert) {
  assert('none', $('#create_account').css('display'));
});

Akui.test("Sign-in form shows on show_form", function (assert) {
  show_form('sign_in');
  assert('block', $('#sign_in').css('display'));
});

Akui.test("Create-account form shows on show_form", function (assert) {
  show_form('create_account');
  assert('block', $('#create_account').css('display'));
});

Akui.test("Create-account form disappears when Sign-in form appears", function (assert) {
  show_form('create_account');
  show_form('sign_in');
  assert('none', form('create_account').css('display'));
});

Akui.test("Sign-in form disappears when Create-account form appears", function (assert) {
  show_form('sign_in');
  show_form('create_account');
  assert('none', form('sign_in').css('display'));
});

// ================================================================
// ==== Cancel buttons
// ================================================================

Akui.test('Sign-in form cancel hides form', function (assert) {
  show_form('sign_in');
  click('#sign_in a.cancel');
  assert('none', form('sign_in').css('display'));
});

Akui.test('Create-account form cancel hides form', function (assert) {
  show_form('create_account');
  click('#create_account a.cancel');
  assert('none', form('create_account').css('display'));
});



