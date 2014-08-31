
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
        :type         => :unknown,
        :english_name => name.to_s.freeze,
        :allow        => {},
        :disable      => {},
        :cleaners     => {},
        :on           => Actions.inject({}) { |memo, a| memo[a] = []; memo}
      }

      @def_fields[:current_field] = name
      yield
      @def_fields[:current_field] = nil
    end

    def on action, meth_name_sym
      fail "Invalid action: #{action.inspect}" unless Actions.include? action
      field[:on][action] << meth_name_sym
      self
    end

    def string *args
      field[:type] = :string
      field[:min]  ||= 0
      field[:max]  ||= 255

      case args.size
      when 0
        # do nothing else
      when 1
        field[:exact_size] = args.first
      when 2
        field[:min] = args.first
        field[:max] = args.last
      else
        fail "Unknown args: #{args.inspect}"
      end

      field[:cleaners][:type] = true
      self
    end

    def allow *props
      props.each { |prop|
        field[:allow][prop] = true
      }
    end

    def disable *props
      props.each { |prop|
        field[:cleaners][prop] = false
      }
    end

    def set_to meth_name_sym
      field[:cleaners][:set_to] ||= []
      field[:cleaners][:set_to] << meth_name_sym
    end

    def equal_to meth_name_sym
      field[:cleaners][:equal_to] ||= []
      field[:cleaners][:equal_to] << meth_name_sym
    end

    def included_in arr
      field[:cleaner][:included_in] ||= []
      field[:cleaner][:included_in].concat arr
    end

    # === String-only methods ===========
    %w{
      strip
      upcase
      to_i
    }.each { |name|
      eval <<-EOF
        def #{name} *args
          fail "Not allowed for \#{field[:type]}" unless field?(:string)
          field[:cleaner][:#{name}] = true
        end
      EOF
    }

    def match *args
      fail "Not allowed for #{field[:type].inspect}" unless field?(:string)
      field[:cleaner][:match] ||= []
      field[:cleaner][:match] << args
    end

    def not_match *args
      fail "Not allowed for #{field[:type].inspect}" unless field?(:string)
      field[:cleaner][:match] ||= []
      field[:cleaner][:match] << args
      self
    end

    def min i
      field[:min] = Integer(i)
      field[:cleaner][:min] = true
      self
    end

    def max i
      field[:max] = Integer(i)
      field[:cleaner][:max] = true
      self
    end

    def within min, max
      field[:within] = [min, max]
      field[:cleaner][:within] = true
      self
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
