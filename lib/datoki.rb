
require 'sequel'

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
      @required = Actions.inject({:all=>[]}) { |memo, name| memo[name] = []; memo }
      @current_field = nil
      @current_on = nil
    end

    def fields
      @fields
    end

    def field? o
      current_field[:type] == :string
    end

    def field name
      @current_field = name

      @fields[@current_field] ||= {
        :on           => {:all=>[]},
        :english_name => name.to_s.freeze
      }

      @current_on = :all
      yield
    end

    def in_on?
      @current_on != :all
    end

    def current_on
      @fields[@current_field][:on][@current_on]
    end

    def current_field
      @fields[@current_field]
    end

    def string *args
      current_field[:type] = :string
      current_field[:min]  ||= 0
      current_field[:max]  ||= 255

      current_on << :check_type
      current_on << :check_size

      case args.size
      when 0
        # do nothing else
      when 1
        current_field[:max] = current_field[:min] = args.first
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
        @current_on = name
        yield
        @current_on = orig
      }

      self
    end

    def required
      if in_on?
        @required[@current_on] << @current_field
      else
        @required[:all] << @current_field
      end
    end

    %w{
      be
      set_to
      equal_to
      nil_if_empty
      one_of_these
    }.each { |name|
      eval <<-EOF
        def #{name} *args
          common_on << [:#{name}, *args]
        end
      EOF
    }

    # === String-only methods ===========
    %w{
      strip
      upcase
      to_i
      match
      not_match
    }.each { |name|
      eval <<-EOF
        def #{name} *args
          fail "Not allowed for \#{field[:type]}" unless field?(String)
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

    def create h
      r = new
      r.create h
      r
    end

  end # === Def_Field

  # ================= Instance Methods ===============

  attr_reader :clean_data

  def initialize
    @new_data = {}
    super
  end

  def create h
    @new_data = h
    @insert_data = {}
    @new_data.each { | k, v |
      defs = self.class.fields[k]
      defs[:on][:all].each { |meta|
        if meta.is_a?(Symbol)
          spec, args = meta, nil
        else
          spec, args = meta
        end

        case spec

        when :check_size

          case defs[:type]
          when :string
            case
            when defs[:min] == defs[:max] && v.size != defs[:max]
              fail Invalid, %^"#{k}}" must be #{defs[:max]} characters long.^
            when v.size < defs[:min]
              fail Invalid, "\"#{k}\" must be longer than #{defs[:min]} in length."
            when v.size > defs[:max]
              fail Invalid, "\"#{k}\" must be shorter or equal to #{defs[:max]} in length."
            end
          end

        when :check_type
          case
          when defs[:type] == :string && !v.is_a?(String)
            fail Invalid, "\"#{k}\" must be a string."
          end

        else
          fail "Unknown requirement: #{spec.inspect}"
        end

        @new_data[k] = v
      }
    }
  end

  def db_insert
    @clean_data
  end

  def db_update
    @clean_data
  end

end # === module Datoki ===
