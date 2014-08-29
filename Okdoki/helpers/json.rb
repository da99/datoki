
require "./Server/Okdoki/Escape_All"
require 'multi_json'

# === Sinatra Helper
#
#
helpers do

  def json *args
    o = {:success => true, :msg=>"Done."}
    args.each { |v|
      if !!v == v
        o[:success] = v
      elsif v.kind_of? String
        o[:msg] = v
      else
        o.merge! v
      end
    }
    content_type :json
    MultiJson.dump Okdoki::Escape_All.escape(o)
  end

end # === module Helper ===

