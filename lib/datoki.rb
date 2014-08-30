
require 'sequel'

module Datoki

  UTC_NOW_DATE = ::Sequel.lit("CURRENT_DATE")
  UTC_NOW_RAW  = "timezone('UTC'::text, now())"
  UTC_NOW      = ::Sequel.lit("timezone('UTC'::text, now())")

  Invalid = Class.new RuntimeError

  Actions = [:all, :create, :read, :update, :update_or_create, :trash, :delete]
  Types   = [:string, :integer, :array]

  class << self

    def included klass
      klass.extend Def_Field
      klass.initialize_def_field
    end

  end # === class self ===

  module Def_Field

    def initialize_def_field
      @def_fields = Actions.inject({:fields=>{}, :current_field=>nil, :current_on=>nil}) { |memo, name|
        memo[name] = {:name=>name, :specs=>[]}
        memo
      }
    end

    def fields
      @def_fields[:fields]
    end

    def field? o
      field[:type] == o
    end

    def field *args
      return fields[@def_field[:current_field]] if args.empty?
      return fields[args.first] unless block_given?

      name = args.first

      fields[name] ||= {
        :name         => name,
        :english_name => name.to_s.freeze
      }

      @def_fields[:current_field] = name
      on nil
      yield
      @def_fields[:current_field] = nil
    end

    def on? args
      if args.empty?
        @def_fields[:current_on] != nil
      else
        @def_fields[:current_on] == args.first
      end
    end

    def on *actions
      return @def_fields[@def_fields[:current_on]] if actions.empty?
      return(@def_fields[:current_on] = @def_fields[actions.first]) unless block_given?

      actions.each { |name|

        fail "Invalid action: #{name.inspect}" unless Actions.include? name
        orig = on
        on name
        yield
        on orig[:name]
      }

      self
    end

    def string *args
      field[:type] = :string
      field[:min]  ||= 0
      field[:max]  ||= 255

      spec :check_type
      spec :check_size

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
      current_field[:min] = Integer(i)
    end

    def max i
      current_field[:max] = Integer(i)
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
              fail Invalid, "\"#{k}\" must be at least #{defs[:min]} characters in length."
            when v.size > defs[:max]
              fail Invalid, "\"#{k}\" must be shorter or equal to #{defs[:max]} characters in length."
            end
          else
            fail "Type not found: #{defs[:type].inspect}"
          end

        when :check_type
          case
          when defs[:type] == :string && !v.is_a?(String)
            fail Invalid, "\"#{k}\" must be a string."
          end

        when :min
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
