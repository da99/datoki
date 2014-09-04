
require 'sequel'

module Datoki

  UTC_NOW_DATE = ::Sequel.lit("CURRENT_DATE")
  UTC_NOW_RAW  = "timezone('UTC'::text, now())"
  UTC_NOW      = ::Sequel.lit("timezone('UTC'::text, now())")

  Invalid = Class.new RuntimeError
  Schema_Conflict = Class.new RuntimeError

  Actions = [:all, :create, :read, :update, :update_or_create, :trash, :delete]
  Types   = [:string, :integer, :array]

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

  end # === class self ===

  module Def_Field

    def initialize_def_field
      @record_errors = false
      @def_fields = {
        :on            => {},
        :fields        => {},
        :current_field => nil
      }
      name = self.to_s.downcase.to_sym
      @schema = {}
      table(name) if Datoki.db.tables.include?(name)
    end

    def record_errors?
      @record_errors
    end

    def record_errors
      @record_errors = true
    end

    def schema
      @schema 
    end

    def table name
      @schema = Datoki.db.schema name
      @schema.each { |pair|
        name, meta = pair
        field name do

          send meta[:type]
          primary_key if meta[:primary_key]
          allow(:nil) if meta[:allow_null]
          default(:db) if meta[:ruby_default] || meta[:default]

          case
          when meta.has_key?(:min_length) && meta.has_key?(:max_length)
            within meta[:min_length], meta[:max_length]
          when meta.has_key?(:min_length)
            min(meta[:min_length])
          when meta.has_key?(:max_length)
            max(meta[:max_length])
          end

          if [:string, :integer].include?(meta[:type]) && !meta.has_key?(:min_length)
            min 1
          end

          case meta[:type]
          when :string
          when :integer
          else
            fail "Unknown db type: #{meta[:type]}"
          end
        end # === field
      }
    end

    def fields
      @def_fields[:fields]
    end

    def inspect_field? target, name, *args
      case target
      when :type
        meta = fields[name]
        fail "Unknown field: #{name.inspect}" unless meta
        return true if args.include?(meta[:type])
        args.include?(:chars) && [:string, :text, :chars].include?(field[:type])
      else
        fail "Unknown arg: #{target.inspect}"
      end
    end

    def field? *args
      inspect_field?(:type, field[:name], *args)
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
        :on           => {}
      }

      @def_fields[:current_field] = name
      yield
      if field[:type] == :unknown
        fail "Type not specified."
      end
      ensure_schema_match

      if field?(:chars) && field[:allow][:nil] && field[:min] < 1
        fail "String can't be both: allow :nil && :min = #{field[:min]}"
      end

      @def_fields[:current_field] = nil
    end

    def ensure_schema_match
      return nil if @schema.empty?
      name = field[:name]

      db_schema = schema[name]

      # === match :text
      db_type = db_schema[:type]
      type = field[:type]
      if db_type != type
        fail Schema_Conflict, ":type => #{db_type.inspect} != #{type.inspect}"
      end

      # === match :max_length
      db_max   = db_schema[:max_length]
      max = field[:max]
      if !db_max.nil? && db_max != max
        fail Schema_Conflict, ":max_length => #{db_max.inspect} != #{max.inspect}"
      end

      # === match :min_length
      db_min   = db_schema[:min_length]
      min = field[:min]
      if !db_min.nil? && db_min != min
        fail Schema_Conflict, ":min_length => #{db_min.inspect} != #{min.inspect}"
      end

      # === match :allow_null
      if db_schema[:allow_null] != field[:allow][:nil]
        fail Schema_Conflict, ":allow_null => #{db_schema[:allow_null].inspect} != #{field[:allow][:nil].inspect}"
      end

      # === match default
      db_default = db_schema[:ruby_default]
      default = field[:default]
      if (db_default.is_a?(String) || db_default.is_a?(Numeric))
        if (default.is_a?(String) || default.is_a?(Numeric))
          if db_default != default
            fail Schema_Conflict, ":default => #{db_default.inspect} != #{default.inspect}"
          end
        end
      end
    end # === def ensure_schema_match

    def on action, meth_name_sym
      fail "Invalid action: #{action.inspect}" unless Actions.include? action
      if field
        field[:on][action] ||= {}
        field[:on][action][meth_name_sym] = true
      else
        @def_fields[:on][action] ||= {}
        @def_fields[:on][action][meth_name_sym] = true
      end
      self
    end

    def ons
      @def_fields[:on]
    end

    def primary_key
      field[:primary_key] = true
    end

    def integer *args
      field[:type] = :integer

      case args.map(&:class)

      when []
        # do nothing

      when [NilClass]
        field[:allow][:nil] = true

      when [NilClass, Fixnum]
        field[:allow][:nil] = true
        field[:max] = args.last

      when [NilClass, Fixnum, Fixnum]
        field[:allow][:nil] = true
        field[:min] = args[-2]
        field[:max] = args.last

      when [Array]
        field[:options] = args.first
        if field[:options].include? nil
          allow :nil
        end

      when [Fixnum]
        field[:max] = args.first

      when [Fixnum, Fixnum]
        field[:min], field[:max] = args

      else
        fail "Unknown args: #{args.inspect}"

      end # === case
    end # === def

    def string *args
      field[:type]   = :string
      field[:min]  ||= 1
      field[:max]  ||= 255
      (field[:strip] = true) unless field.has_key?(:strip)

      case args.map(&:class)

      when []
        # do nothing

      when [NilClass]
        field[:allow][:nil] = true

      when [NilClass, Fixnum]
        field[:allow][:nil] = true
        field[:max] = args.last

      when [NilClass, Fixnum, Fixnum]
        field[:allow][:nil] = true
        field[:min] = args[-2]
        field[:max] = args.last

      when [Fixnum]
        field[:max] = args.last

      when [Fixnum, Fixnum]
        field[:min], field[:max] = args

      else
        fail "Unknown args: #{args.inspect}"

      end # === case

    end # === def

    def allow *props
      props.each { |prop|
        field[:allow][prop] = true
      }
    end # == def

    def disable *props
      props.each { |prop|
        case prop
        when :strip
          field[:strip] = false
        else
          field[:cleaners][prop] = false
        end
      }
    end

    def default_enable *props
      props.each { |prop|
        next if field[:cleaners].has_key?(prop)
        field[:cleaners][prop] = true
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
      next if !is_set && field[:default] == :db
      next if field[:allow][:nil] && (!is_set || is_nil)

      if is_set 
        val! new_data[field_name]
      elsif field.has_key?(:default)
        val! field[:default]
      end

      if val.is_a?(String) && field[:strip]
        val! val.strip
      end

      if val.is_a?(String) && field[:allow][:nil] && val.empty?
        val! nil
      end

      catch :error_saved do

        if field[:type] == :integer && val.is_a?(String)
          clean_val = Integer(val) rescue String
          if clean_val == String
            fail! "!English_name must be numeric."
          else
            val! clean_val
          end
        end

        # === check type =================
        case field[:type]
        when :string
        when :integer
        when nil
          # do nothing
        else
          fail "Unknown type: #{field[:type].inspect}"
        end
        # ================================

        # === check required. ============
        if val.nil? && !field[:allow][:nil]
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
        if field?(:integer)
          val! val.to_i
        end
        # ================================

        # === :strip if necessary ========
        if field?(:string) && field[:strip] && val.is_a?(String)
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
              case field[:type]
              when :string, :array, :integer, String, Array, Integer
                # do nothing
              else
                fail "Unknown type: #{field[:type].inspect}"
              end

              case
              when field?(:integer) && !val.is_a?(Integer)
                fail! "!English_name needs to be an integer."
              when field?(:string) && !val.is_a?(String)
                fail! "!English_name needs to be a String."
              when field?(:array) && !val.is_a?(Array)
                fail! "!English_name needs to be an Array."
              end

            when :exact_size
              if val.size != field[:exact_size]
                case
                when field?(:string) || val.is_a?(String)
                  fail! "!English_name needs to be !exact_size in length."
                when field?(:array) || val.is_a?(Array)
                  fail! "!English_name needs to have exactly !exact_size."
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

            when :min
              target = val.is_a?(Numeric) ? val : val.size

              if target < field[:min]
                err_msg = case
                          when field?(:string) || val.is_a?(String)
                            "!English_name must be at least !min in length."
                          when field?(:array) || val.is_a?(Array)
                            "!English_name must have at least !min."
                          else
                            "!English_name must be at least !min."
                          end

                fail! err_msg
              end

            when :max
              target = val.is_a?(Numeric) ? val : val.size

              if target > field[:max]
                err_msg = case
                          when field?(:string) || val.is_a?(String)
                            "!English_name has a maximum length of !max."
                          when field?(:array) || val.is_a?(Array)
                            "!English_name has a maximum of !max."
                          else
                            "!English_name can't be more than !max."
                          end

                fail! err_msg
              end

            when :within
              target = val.is_a?(Numeric) ? val : val.size
              if target < field[:min] || target > field[:max]
                fail! "!English_name must be between !min and !max"
              end

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



