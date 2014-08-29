
module Okdoki
  class Bool_Params

    def initialize app, options = nil
      @app = app
    end

    def call env
      h = env['rack.request.form_hash']
      if h
        h.keys.each { |k|
          v = h[k]
          if k['is_']
            h[k] = true  if v == 'true'
            h[k] = false if v == 'false'
          end
        }
      end
      @app.call env
    end

  end # === class Bool_Params ===
end # === module Okdoki ===

if respond_to?(:use, true)

  use Okdoki::Bool_Params

end # === if sinatra dsl
