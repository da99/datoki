
module Okdoki_Session_Helpers # === Sinatra Helpers ================================

  def logged_in?
    !!user
  end

  def user
    @screen_name ||= request.env['ok.user']
  end

  def sign_in c
    log_out
    session[:screen_name] = c.screen_names.first.screen_name
    true
  end

  def log_out
    session.keys.each { |k| session[k] = nil }
    session.clear
    cookies.keep_if { |k,v| false }
  end

end # === module Helpers ============================================

if respond_to? :helpers, true
  helpers Okdoki_Session_Helpers
end # if :helpers?



