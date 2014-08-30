
module Datoki

  UTC_NOW_RAW  = "timezone('UTC'::text, now())"
  UTC_NOW      = ::Sequel.lit("timezone('UTC'::text, now())")
  UTC_NOW_DATE = ::Sequel.lit("CURRENT_DATE")

  Invalid = Class.new RuntimeError

  Actions = [:create, :read, :update, :update_or_create, :trash, :delete]

  class << self

    def included klass
      klass.extend Def_Field
      klass.initialize_def_field
    end

  end # === class self ===

  module Def_Field

    def initialize_def_field
      @fields = {}
      @current_field = nil
      @current_on = nil
    end

    def fields
      @fields
    end

    def field name
      @current_field = name

      @fields[@current_field] ||= {
        :on           => {:all=>[]},
        :english_name => name.to_s.freeze
      }

      @current_on = current_field[:on][:all]
      yield
    end

    def current_on
      @current_on
    end

    def current_field
      @fields[@current_field]
    end

    def string *args
      current_field[:type] = :string
      current_field[:min]  ||= 0
      current_field[:max]  ||= 255

      case args.size
      when 0
        # do nothing else
      when 1
        current_field[:max] = args.first
      when 2
        current_field[:min] = args.first
        current_field[:max] = args.last
      else
        fail "Unknown args: #{args.inspect}"
      end

      self
    end

    def on *actions
      actions.each { |name|

        fail "Invalid action: #{name.inspect}" unless Actions.include? name
        current_field[:on][name] ||= []

        orig = current_on
        @current_on = current_field[:on][name]
        yield
        @current_on = orig
      }

      self
    end

    %{
      required
      be
      strip
      upcase
      to_i
      set_to
      equal_to
      nil_if_empty
      match
      not_match
      one_of_these
    }.each { |name|
      eval <<-EOF
        def #{name} *args
          common_on << [:#{name}, *args]
        end
      EOF
    }

    def min i
      current_on << [:min, Integer(i)]
    end

    def max i
      current_on << [:max, Integer(i)]
    end

    def within min, max
      current_on << [:range, Integer(min) - 1, Integer(max) - 1]
    end

    def min_max min, max
      current_on << [:range, Integer(min), Integer(max)]
    end

  end # === Def_Field

  def create h
    r = new
    r.create h
    r
  end

  # ================= Instance Methods ===============

  def initialize
    @new_data = {}
    super
  end

  def create h
    @new_data = h
    @insert_data = {}
    @new_data.each { | k, v |
      defs = self.class.fields[k]
      case defs[:type]
      when :string
        fail Invalid, "\"#{k}\" must be a string." unless v.is_a?(String)
        fail Invalid, "\"#{k}\" must be longer than #{defs[:min]} in length." if v.size < defs[:min]
        fail Invalid, "\"#{k}\" must be shorter or equal to #{defs[:max]} in length." if v.size > defs[:max]
        @new_data[k] = v
      else
        fail "Unknown type: #{defs[:type].inspect}"
      end
    }
  end

end # === module Datoki ===
