
module Okdoki

  class No_Cache

    def initialize app, options = nil
      @app = app
    end

    def call env
      results = @app.call(env)
      return results unless env['HTTP_ACCEPT']['html']
      headers = results[1]

      headers["Expires"]       = "Tue, 03 Jul 2001 06:00:00 GMT"
      headers["Last-Modified"] = "Wed, 15 Nov 1995 04:58:08 GMT"
      headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0, post-check=0, pre-check=0"
      headers["Pragma"]        = "no-cache"

      results
    end

  end # === class No_Cache ===

end # === module Okdoki ===

use Okdoki::No_Cache if respond_to?(:use, true)
