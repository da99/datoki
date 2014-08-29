
#
# Make sure person is not trying to pretend to be someone
# else.
#
#

module Okdoki
  class As_This_Life

    def initialize app, options = nil
      @app = app
      @options = {:session_key => 'rack.session'}.merge(options || {})
    end

    def call env
      user = env['ok.user']
      return @app.call(env) unless user

      h = env['rack.request.form_hash']
      return @app.call(env) unless h

      h['as'] = nil
      default = user.screen_names.first.screen_name

      if h['as_this_life']
        if user.is_a?(h['as_this_life'])
          h['as'] = h['as_this_life']
        else
          h['as'] = default
        end
      end

      h['as_this_life'] = nil

      @app.call env
    end

  end # === class As_This_Life ===
end # === module Okdoki ===


if respond_to?(:use, true)
  use Okdoki::As_This_Life
end
