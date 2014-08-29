#
# Module: Okdoki_Session
#
#   This manages the creation/destruction of sessions.
#   It also guards against making changes to the database
#   without a session.
#
#   Guard options include:
#     :skip   => Useful to guard against non-HEAD/GET actions.
#     :guard  => Useful to guard GET actions
#

class Okdoki_Session

  def initialize app, options
    @app     = app
    @options = {:session_key => 'rack.session'}.merge(options)
    @skip    = @options[:skip] || []
    @guard   = @options[:guard] || []
  end

  def call env
    meth    = env['REQUEST_METHOD']
    path    = env['PATH_INFO']
    session = env[@options[:session_key]]

    full = "#{meth}:#{path}"
    if session['screen_name'] || !@guard.include?(full) && (['HEAD', 'GET'].include?(meth) || @skip.include?(full))
      return @app.call env
    end

    content = MultiJson.dump({:success=>false, :msg=>"You have to re-login."})
    [401, {'Content-Type' => 'application/json'}, content]
  end

end # === class Session ===

if respond_to? :helpers, true

  require 'sinatra/cookies'
  use     Okdoki_Session,  skip: ['POST:/sign-in', 'POST:/user']

end # if :helpers?


