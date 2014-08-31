
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
      @record_errors = false
      @def_fields = Actions.inject({:fields=>{}, :current_field=>nil, :current_on=>nil}) { |memo, name|
        memo[name] = {:name=>name, :specs=>[]}
        memo
      }
    end

    def record_errors?
      @record_errors
    end

    def record_errors
      @record_errors = true
    end

    def fields
      @def_fields[:fields]
    end

    def field? o
      field[:type] == o
    end

    def field *args
      return fields[@def_fields[:current_field]] if args.empty?
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

    def set_to *args
      field[:cleaners][:set_to] ||= []
      field[:cleaners][:set_to].concat args
    end

    def equal_to *args
      field[:cleaners][:equal_to] ||= []
      field[:cleaners][:equal_to].concat args
    end

    def included_in arr
      field[:cleaners][:included_in] ||= []
      field[:cleaners][:included_in].concat arr
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
          field[:cleaners][:#{name}] = true
        end
      EOF
    }

    def match *args
      fail "Not allowed for #{field[:type].inspect}" unless field?(:string)
      field[:cleaners][:match] ||= []
      field[:cleaners][:match] << args
    end

    def not_match *args
      fail "Not allowed for #{field[:type].inspect}" unless field?(:string)
      field[:cleaners][:not_match] ||= []
      field[:cleaners][:not_match] << args
      self
    end

    def min i
      field[:min] = Integer(i)
      field[:cleaners][:min] = true
      self
    end

    def max i
      field[:max] = Integer(i)
      field[:cleaners][:max] = true
      self
    end

    def within min, max
      field[:within] = [min, max]
      field[:cleaners][:within] = true
      self
    end

    def create h
      r = new
      r.create h
    end

  end # === Def_Field

  # ================= Instance Methods ===============

  def initialize data = nil
    @data       = nil
    @new_data   = nil
    @field_name = nil
    @clean_data = nil
    @errors     = nil
  end

  def errors
    @errors ||= []
  end

  def clean_data
    @clean_data ||= {}
  end

  def new_data
    @new_data ||= {}
  end

  def fail! msg
    err_msg = msg.gsub(/!([a-z\_\-]+)/i) { |raw|
      name = $1
      case name
      when "English_name"
        self.class.fields[field_name][:english_name].capitalize.gsub('_', ' ')
      when "ENGLISH_NAME"
        self.class.fields[field_name][:english_name].upcase.gsub('_', ' ')
      when "max", "min"
        self.class.fields[field_name][name.downcase.to_sym]
      else
        fail "Unknown value: #{name}"
      end
    }

    if self.class.record_errors?
      errors << [err_msg, field_name, val]
    else
      fail Invalid, err_msg
    end
  end

  def field_name *args
    case args.size
    when 0
      fail "Field name not set." unless @field_name
      @field_name
    when 1
      @field_name = args.first
    else
      fail "Unknown args: #{args.inspect}"
    end
  end

  def val *args
    case args.size
    when 0
      if clean_data.has_key?(field_name)
        clean_data[field_name]
      else
        new_data[field_name]
      end
    when 1
    else
      fail "Unknown args: #{args.inspect}"
    end
  end

  def run action
    self.class.fields.each { |f_name, field|
      field_name f_name
      field[:cleaners].each { |cleaner, args|
        next if args === false
        next if field[:allow][:nil] && (!new_data.has_key?(field[:name]) || new_data[:name].nil?)

        case cleaner

        when :type
          case field[:type]
          when :string
            fail("!English_name needs to be a String.") unless val.is_a?(String)
          else
            fail "Unknown type: #{field[:type].inspect}"
          end

        when :set_to
          args.each { |meth|
            val send(meth)
          }

        when :equal_to
          args.each { |pair|
            meth, msg, other = pair
            target = send(meth)
            fail!(msg || "!English_name must be equal to: #{target.inspect}") unless val == target
          }

        when :included_in
          arr, msg, other = args
          fail!(msg || "!English_name must be one of these: #{arr.join ', '}") unless arr.include?(val)

        when :strip
          val val.strip

        when :upcase
          val val.upcase

        when :to_i
          val val.to_i

        when :match
          args.each { |pair|
            regex, msg, other = pair
            if val !~ regex
              fail!(msg || "!English_name must match #{regex.inspect}")
            end
          }

        when :not_match
          args.each { |pair|
            regex, msg, other = pair
            if val =~ regex
              fail!(msg || "!English_name must not match #{regex.inspect}")
            end
          }

        when :min
          target = val.is_a?(Numeric) ? val : val.size
          if target < field[:min]
            fail! "!English_name must be equal or more than !min"
          end

        when :max
          target = val.is_a?(Numeric) ? val : val.size
          if target >= field[:max]
            fail! "!English_name must be equal or less than !max"
          end

        when :within
          target = val.is_a?(Numeric) ? val : val.size
          if target < field[:min] || target > field[:max]
            fail! "!English_name must be within !min and !max"
          end

        else
          fail "Cleaner not implemented: #{cleaner.inspect}"
        end # === case cleaner

      } # === cleaners
    } # === field
  end

  def create new_data
    @new_data = new_data
    run :create
    self
  end

  def update new_data
    @new_data = new_data
    run :update
    self
  end

end # === module Datoki ===
