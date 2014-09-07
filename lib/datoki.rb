
require 'sequel'

module Datoki

  UTC_NOW_DATE = ::Sequel.lit("CURRENT_DATE")
  UTC_NOW_RAW  = "timezone('UTC'::text, now())"
  UTC_NOW      = ::Sequel.lit("timezone('UTC'::text, now())")

  Invalid = Class.new RuntimeError
  Schema_Conflict = Class.new RuntimeError

  Actions       = [:all, :create, :read, :update, :update_or_create, :trash, :delete]
  Char_Types    = [:varchar, :text]
  Numeric_Types = [:smallint, :integer, :bigint, :decimal, :numeric]
  Types         = Char_Types + Numeric_Types + [:datetime]

  class << self

    def included klass
      klass.extend Def_Field
      klass.initialize_def_field
    end

    def db db = :return
      return @db if db == :return
      @db = db
      @tables = @db.tables
    end

    def db_type_to_ruby type, alt = nil
      if Datoki::Types.include?( type.to_sym )
        type.to_sym
      elsif type['character varying']
        :varchar
      elsif Datoki::Types.include?(alt)
        alt
      else
        fail("Unknown db type: #{type.inspect}")
      end
    end

  end # === class self ===

  module Def_Field

    attr_reader :ons, :fields

    def initialize_def_field
      @record_errors = false
      @ons           = {}
      @fields        = {}
      @current_field = nil
      @schema        = {}
      @schema_match  = false
      name = self.to_s.downcase.to_sym
      table(name) if Datoki.db.tables.include?(name)
      if @schema.empty?
        @schema_match = true
      end
    end

    def schema_match?
      @schema_match
    end

    def record_errors?
      @record_errors
    end

    def record_errors
      @record_errors = true
    end

    def table name
      @schema = {}
      Datoki.db.schema(name).each { |pair|
        @schema[pair.first] = pair.last
      }
      schema
    end

    def schema *args
      case args.size

      when 0
        @schema 

      when 1
        result = @schema[args.first]
        fail "Unknown field: #{args.first.inspect}" unless result
        result

      else
        fail "Unknown args: #{args.inspect}"

      end
    end

    def inspect_field? target, name, *args
      case target
      when :type
        meta = fields[name]
        fail "Unknown field: #{name.inspect}" unless meta
        return true if args.include?(meta[:type])
        return true if args.include?(:chars) && Char_Types.include?(meta[:type])
        args.include?(:numeric) && Numeric_Types.include?(meta[:type])
      else
        fail "Unknown arg: #{target.inspect}"
      end
    end

    def field? *args
      inspect_field?(:type, field[:name], *args)
    end

    def field *args
      return fields[@current_field] if args.empty?
      return fields[args.first] unless block_given?

      name = args.first

      fail "#{name.inspect} already defined." if fields[name]

      fields[name] = {
        :name         => name,
        :type         => :unknown,
        :english_name => name.to_s.freeze,
        :allow        => {:null => false},
        :disable      => {},
        :cleaners     => {},
        :on           => {}
      }

      @current_field = name

      if field? :chars
        field[:allow][:strip] = true
      end

      yield

      fail("Type not specified for #{name.inspect}") if field[:type] == :unknown

      # === check :allow_null and :min are not both set.
      if field?(:chars) && field[:allow][:null] && field.has_key?(:min) && field[:min] < 1
        fail "#{field[:type].inspect} can't be both: allow :null && :min = #{field[:min]}"
      end

      # === Ensure schema matches with field definition:
      schema_match

      @current_field = nil
    end # === def field

    def schema_match target = :current
      return true if schema_match?

      if target == :all # === do a schema match on entire table
        schema.each { |name, db_schema|
          orig_field = @current_field
          @current_field = name
          schema_match
          @current_field = orig_field
        }

        @schema_match = true
        return true
      end # === if target

      return true if field[:schema_match]

      name      = @current_field
      db_schema = schema[@current_field]

      if db_schema && !field
        check_null
        return true
      end

      if field?(:chars)
        if !field[:min].is_a?(Numeric) || field[:min] < 0
          fail ":min not properly defined for #{name.inspect}: #{field[:min].inspect}"
        end

        if !field[:max].is_a?(Numeric)
          fail ":max not properly defined for #{name.inspect}: #{field[:max].inspect}"
        end
      end

      if db_schema.has_key?(:max_length)
        field[:max] = db_schema[:max_length]
        if field[:max] != db_schema[:max_length]
          fail Schema_Conflict, ":max: #{db_schema[:max_length].inspect} != #{field[:max].inspect}"
        end
      end

      if db_schema[:primary_key] != !field[:primary_key]
        fail Schema_Conflict, ":primary_key: #{db_schema[:primary_key].inspect} != #{field[:primary_key].inspect}"
      end

      # === match :type
      db_type = Datoki.db_type_to_ruby db_schema[:db_type], db_schema[:type]
      type    = field[:type]
      if db_type != type
        fail Schema_Conflict, ":type: #{db_type.inspect} != #{type.inspect}"
      end

      # === match :max_length
      db_max = db_schema[:max_length]
      max    = field[:max]
      if !db_max.nil? && db_max != max
        fail Schema_Conflict, ":max_length: #{db_max.inspect} != #{max.inspect}"
      end

      # === match :min_length
      db_min = db_schema[:min_length]
      min    = field[:min]
      if !db_min.nil? && db_min != min
        fail Schema_Conflict, ":min_length: #{db_min.inspect} != #{min.inspect}"
      end

      # === match :allow_null
      if db_schema[:allow_null] != field[:allow][:null]
        fail Schema_Conflict, ":allow_null: #{db_schema[:allow_null].inspect} != #{field[:allow][:null].inspect}"
      end

      field[:schema_match] = true
    end

    def on action, meth_name_sym
      fail "Invalid action: #{action.inspect}" unless Actions.include? action
      if field
        field[:on][action] ||= {}
        field[:on][action][meth_name_sym] = true
      else
        @ons[action] ||= {}
        @ons[action][meth_name_sym] = true
      end
      self
    end

    def primary_key
      field[:primary_key] = true
    end

    def text *args
      type :text, *args
    end

    Types.each { |name|
      eval <<-EOF
        def #{name} *args
          type :#{name}, *args
        end
      EOF
    }

    def type name, *args
      field[:type] = name
      disable :null

      if field?(:chars) || field?(:numeric)
        field[:min] ||= 1
      end

      if field?(:chars)
        field[:max] ||= 255
        enable :strip
      end

      case args.map(&:class)

      when []
        # do nothing

      when [Array]
        field[:options] = args.first
        enable(:null) if field[:options].include? nil
        disable :min, :max

      when [NilClass]
        enable :null

      when [NilClass, Fixnum]
        enable :null
        field[:min] = args.last

      when [NilClass, Fixnum, Fixnum]
        field[:allow][:null] = true
        field[:min] = args[-2]
        field[:max] = args.last

      when [Fixnum]
        field[:min] = args.first

      when [Fixnum, Fixnum]
        field[:min], field[:max] = args

      else
        fail "Unknown args: #{args.inspect}"

      end # === case

    end # === def

    def enable *props
      props.each { |prop|
        case prop
        when :strip, :null
          field[:allow][prop] = true
        else
          field[:cleaners][prop] = true
        end
      }
    end

    def disable *props
      props.each { |prop|
        case prop
        when :min, :max
          field.delete prop
        when :strip, :null
          field[:allow][prop] = false
        else
          field[:cleaners][prop] = false
        end
      }
    end

    def default val
      field[:default] = val
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
      upcase
      to_i
    }.each { |name|
      eval <<-EOF
        def #{name} *args
          fail "Not allowed for \#{field[:type]}" unless field?(:chars)
          enable :#{name}
        end
      EOF
    }

    def match *args
      fail "Not allowed for #{field[:type].inspect}" unless field?(:chars)
      field[:cleaners][:match] ||= []
      field[:cleaners][:match] << args
    end

    def not_match *args
      fail "Not allowed for #{field[:type].inspect}" unless field?(:chars)
      field[:cleaners][:not_match] ||= []
      field[:cleaners][:not_match] << args
      self
    end

    def create h = {}
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

    self.class.schema_match(:all)
  end

  def errors
    @errors ||= {}
  end

  def errors?
    @errors && !@errors.empty?
  end

  def save_error msg
    @errors ||= {}
    @errors[field_name] ||= {}
    @errors[field_name][:msg] = msg
    @errors[field_name][:value] = val
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
      when "max", "min", "exact_size"
        self.class.fields[field_name][name.downcase.to_sym]
      else
        fail "Unknown value: #{name}"
      end
    }

    if self.class.record_errors?
      save_error err_msg
      throw :error_saved
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

  def val
    if clean_data.has_key?(field_name)
      clean_data[field_name]
    else
      new_data[field_name]
    end
  end

  def val! new_val
    clean_data[field_name] = new_val
  end

  def field *args
    case args.size
    when 0
      self.class.fields[field_name]
    when 1
      self.class.fields[args.first]
    else
      fail "Unknown args: #{args.inspect}"
    end
  end

  def field? *args
    self.class.inspect_field? :type, field_name, *args
  end

  def run action
    self.class.fields.each { |f_name, f_meta|

      field_name f_name
      is_set    = new_data.has_key?(field_name)
      is_update = action == :update
      is_nil    = is_set && new_data[field_name].nil?

      # === Should the field be skipped? ===============
      next if !is_set && is_update
      next if !is_set && field[:primary_key]
      next if field[:allow][:null] && (!is_set || is_nil)

      if is_set 
        val! new_data[field_name]
      elsif field.has_key?(:default)
        val! field[:default]
      end

      if val.is_a?(String) && field[:allow][:strip]
        val! val.strip
      end

      catch :error_saved do

        if field?(:numeric) && val.is_a?(String)
          clean_val = Integer(val) rescue String
          if clean_val == String
            fail! "!English_name must be numeric."
          else
            val! clean_val
          end
        end

        # === check required. ============
        if val.nil? && !field[:allow][:null]
          fail! "!English_name is required."
        end
        # ================================

        # === check min, max ======
        if val.is_a?(String) || val.is_a?(Numeric)
          case [field[:min], field[:max]].map(&:class)

          when [NilClass, NilClass]
            # do nothing

          when [NilClass, Fixnum]
            case
            when val.is_a?(String) && val.size > field[:max]
              fail! "!English_name can't be longer than !max characters."
            when val.is_a?(Numeric) && val > field[:max]
              fail! "!English_name can't be higher than !max."
            end

          when [Fixnum, NilClass]
            case
            when val.is_a?(String) && val.size < field[:min]
              fail! "!English_name can't be shorter than !min characters."
            when val.is_a?(Numeric) && val < field[:min]
              fail! "!English_name can't be less than !min."
            end

          when [Fixnum, Fixnum]
            case
            when val.is_a?(String) && (val.size < field[:min] || val.size > field[:max])
              fail! "!English_name must be between !min and !max characters."
            when val.is_a?(Numeric) && (val < field[:min] || val > field[:max])
              fail! "!English_name must be between !min and !max."
            end

          else
            fail "Unknown values for :min, :max: #{field[:min].inspect}, #{field[:max].inspect}"
          end
        end # === if
        # ================================

        # === to_i if necessary ==========
        if field?(:numeric)
          val! val.to_i
        end
        # ================================

        # === :strip if necessary ========
        if field?(:chars) && field[:allow][:strip] && val.is_a?(String)
          val! val.strip
        end
        # ================================

        # === Is value in options? =======
        if field[:options]
          if !field[:options].include?(val)
            fail! "!English_name can only be: #{field[:options].map(&:inspect).join ', '}"
          end
        end
        # ================================

        field[:cleaners].each { |cleaner, args|
          next if args === false # === cleaner has been disabled.

            case cleaner

            when :type
              case
              when field?(:numeric) && !val.is_a?(Integer)
                fail! "!English_name needs to be an integer."
              when field?(:chars) && !val.is_a?(String)
                fail! "!English_name needs to be a String."
              end

            when :exact_size
              if val.size != field[:exact_size]
                case
                when field?(:chars) || val.is_a?(String)
                  fail! "!English_name needs to be !exact_size in length."
                else
                  fail! "!English_name can only be !exact_size in size."
                end
              end

            when :set_to
              args.each { |meth|
                val! send(meth)
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

            when :upcase
              val! val.upcase

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

            else
              fail "Cleaner not implemented: #{cleaner.inspect}"
            end # === case cleaner


        } # === field[:cleaners].each

        field[:on][action].each { |meth, is_enabled|
          next unless is_enabled
          send meth
        } if field[:on][action]

      end # === catch :error_saved
    } # === field

    return if errors?

    self.class.ons.each { |action, meths|
      meths.each { |meth, is_enabled|
        next unless is_enabled
        catch :error_saved do
          send meth
        end
      }
    }
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



