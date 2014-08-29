


# ==================================================
# ==================================================

describe( 'app' ) do

  # #1
  it('escapes url params');

  # #2
  it('escapes post data');

  # #3
  it('escapes query string');

  # #4
  it('escapes screen names, not just canon-ize them')

  # #5
  it('exits gracefully for SIGTERM')

  # #6
  it('exits gracefully for SIGINT')

  # #7
  it( 'renders an error page just with {msg: ""}' )

  # #8
  it( 'uses Content Securoty polciy')

  # #9
  it( 'escapes params for each route' )

  # #10
  it 'prevents session hijacking (rack protection) when useragent changes'

  # #11
  it 'escapes all URL fields in the database (_url) to RFC specs'

  # #12
  it 'sanitizes :return_to url after sign-in & account creation'

  # # 13
  it 'deletes all cookies up log-out'

  # # 14
  it 'escapes HTML using Okdoki::Escape_All, not Mustache escapeHTML'


  # # 15
  it 'escapes json'

  # # 16
  it 'escapes html not starting with a valid html5'

  # # 17
  it 'makes sure X-REAL-IP is set in the env'

  # # 18
  it 'uses no-cache middleware'

  # # 19
  it 'clears :as_this_life if invalid (ie impersonation'

end # == desc


describe( 'Unauthenticated users:') do
  # 1
  it('sends a secure/HTTP only cookie')

  # 2
  it('does not store any data in session')

  # 3
  it('sends a JSON response if unauthenticated for POST requests, JSON-accept')

  # 4
  it('sends a JSON response if 403/forbidden   for POST requests, JSON-accept')

  # 5
  it('sends a HTTP response if unauthenticated for POST requests, HTTP-accept')

  # 6
  it 'prevents access if CSRF is invalid.'

end # === desc

describe( 'Auth users (aka Customers)') do

  it('checks as_this_life belongs to customer')

end # === describe


describe "App" do

    it 'runs'

    it 'includes a _csrf token' do

      #  get('/', function (err, resp, body, extra)
      #    expect(extra._csrf).match(/[a-z0-9\_\-]{24}/i);
      #    done();
      #

    end

    it( 'escapes .body (form) data' )
    it( 'escapes .params data' )
    it( 'escapes .query data' )
    it( 'escapes .cookie data' )


  describe( 'Customer', function () {

end # === desc



