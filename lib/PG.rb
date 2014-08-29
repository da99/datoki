

module Okdoki
  module Model
    module PG
      UTC_NOW_RAW  = "timezone('UTC'::text, now())"
      UTC_NOW      = ::Sequel.lit("timezone('UTC'::text, now())")
      UTC_NOW_DATE = ::Sequel.lit("CURRENT_DATE")
    end # === module Sequel ===
  end # === module Model ===
end # === module Okdoki ===
