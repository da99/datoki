
require 'sequel'

module Datoki

  UTC_NOW_DATE = ::Sequel.lit("CURRENT_DATE")
  UTC_NOW_RAW  = "timezone('UTC'::text, now())"
  UTC_NOW      = ::Sequel.lit("timezone('UTC'::text, now())")

  Invalid         = Class.new RuntimeError
  Schema_Conflict = Class.new RuntimeError

  Actions       = [:all, :create, :read, :update, :update_or_create, :trash, :delete]
  Char_Types    = [:varchar, :text]
  Numeric_Types = [:smallint, :integer, :bigint, :decimal, :numeric]
  Types         = Char_Types + Numeric_Types + [:datetime]

  Key_Not_Found = lambda { |hash, key|
    fail ArgumentError, "Key not found: #{key.inspect}"
  }

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

    attr_reader :ons, :fields, :fields_as_required

    def initialize_def_field
      @on_doc             = []
      @ons                = {}
      @fields             = {} # Ex: {:name=>{}, :age=>{}}
      @fields_as_required = {} # Ex: {:name!=>:name}
      @current_field      = nil
      @schema             = {}
      @schema_match       = false
      @table_name         = nil
      name = self.to_s.downcase.to_sym
      table(name) if Datoki.db.tables.include?(name)
    end

    def schema_match?
      @schema_match
    end

    def table name
      if !@schema.empty? || @table_name
        fail "Schema/table already defined: #{@table_name.inspect}"
      end

      db_schema = Datoki.db.schema(name)

      if !db_schema
        fail "Schema not found for: #{name.inspect}"
      end

      @table_name = name

      db_schema.each { |pair|
        @schema[pair.first] = pair.last
      }

      if @schema.empty?
        @schema_match = true
      end

      schema
    end

    def html_escape
      @html_escape ||= begin
                         fields.inject({}) { |memo, (name, meta)|
                           memo[name] = meta[:html_escape]
                           memo
                         }
                       end
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

    def allow sym
      fields[@current_field][:allow][sym] = true;
    end

    def field *args
      return fields[@current_field] if args.empty?
      return fields[args.first] unless block_given?

      name = args.first

      fail "#{name.inspect} already defined." if fields[name]
      fields_as_required[:"#{name}!"] = name

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

      if schema[name]
        if schema[name].has_key? :max_length
          fields[name][:max] = schema[name][:max_length]
        end
      end

      yield

      fail("Type not specified for #{name.inspect}") if field[:type] == :unknown

      # === check :allow_null and :min are not both set.
      if field?(:chars) && field[:allow][:null] && field.has_key?(:min) && field[:min] < 1
        fail "#{field[:type].inspect} can't be both: allow :null && :min = #{field[:min]}"
      end

      # === Ensure schema matches with field definition:
      schema_match

      field[:html_escape] = case
                            when field[:html_escape]
                              field[:html_escape]
                            when field?(:numeric)
                              :number
                            when field?(:chars)
                              :string
                            else
                              fail "Unknown html_escape for: #{field[:name].inspect}"
                            end

      @current_field = nil
    end # === def field

    def schema_match target = :current
      return true if !@table_name
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

      name      = @current_field
      db_schema = schema[@current_field]

      if db_schema && !field && db_schema[:type] != :datetime
        fail Schema_Conflict, "#{name}: #{name.inspect} has not been defined."
      end

      return true if field[:schema_match]

      if db_schema[:allow_null] != field[:allow][:null]
        fail Schema_Conflict, "#{name}: :allow_null: #{db_schema[:allow_null].inspect} != #{field[:allow][:null].inspect}"
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
        if field[:max] != db_schema[:max_length]
          fail Schema_Conflict, "#{name}: :max: #{db_schema[:max_length].inspect} != #{field[:max].inspect}"
        end
      end

      if !!db_schema[:primary_key] != !!field[:primary_key]
        fail Schema_Conflict, "#{name}: :primary_key: #{db_schema[:primary_key].inspect} != #{field[:primary_key].inspect}"
      end

      # === match :type
      db_type = Datoki.db_type_to_ruby db_schema[:db_type], db_schema[:type]
      type    = field[:type]
      if db_type != type
        fail Schema_Conflict, "#{name}: :type: #{db_type.inspect} != #{type.inspect}"
      end

      # === match :max_length
      db_max = db_schema[:max_length]
      max    = field[:max]
      if !db_max.nil? && db_max != max
        fail Schema_Conflict, "#{name}: :max_length: #{db_max.inspect} != #{max.inspect}"
      end

      # === match :min_length
      db_min = db_schema[:min_length]
      min    = field[:min]
      if !db_min.nil? && db_min != min
        fail Schema_Conflict, "#{name}: :min_length: #{db_min.inspect} != #{min.inspect}"
      end

      # === match :allow_null
      if db_schema[:allow_null] != field[:allow][:null]
        fail Schema_Conflict, "#{name}: :allow_null: #{db_schema[:allow_null].inspect} != #{field[:allow][:null].inspect}"
      end

      field[:schema_match] = true
    end

    attr_reader :on_doc
    def on *args
      return(field_on *args) if !block_given?
      @on_doc << [args, Proc.new]
      self
    end

    def field_on action, meth_name_sym
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
      if field?(:unknown)
        if schema[field[:name]]
          type schema[field[:name]][:type]
        else
          type :integer
        end
      end

      true
    end

    def text *args
      type :text, *args
    end

    def href *args
      field[:html_escape] = :href
      case args.map(&:class)
      when []
        varchar 1, 255
      when [NilClass]
        varchar nil, 1, (schema[field[:name]] ? schema[field[:name]][:max_length] : 255)
      else
        varchar *args
      end
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

      if field? :chars

        enable :strip

        if field?(:text)
          field[:max] ||= 4000
        else
          field[:max] ||= 255
        end

        if schema[name] && !schema[name][:allow_null]
          field[:min] = 1
        end

      end # === if field? :chars

      case args.map(&:class)

      when []
        # do nothing

      when [Array]
        field[:options] = args.first
        enable(:null) if field[:options].include? nil
        disable :min, :max

      when [NilClass]
        if field?(:chars)
          fail "A :min and :max is required for String fields."
        end

        enable :null

      when [NilClass, Fixnum, Fixnum]
        field[:allow][:null] = true
        field[:min] = args[-2]
        field[:max] = args.last

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

    def create raw
      raw[:create] = self
      new raw
    end

  end # === Def_Field =====================================================

  # ================= Instance Methods ===============

  attr_reader :error
  def initialize unknown = nil
    @data       = nil
    @field_name = nil
    @clean      = nil
    @error      = nil
    @skips      = {}

    if unknown
      if unknown.keys.all? { |f| self.class.fields.has_key?(f) }
        @data = unknown
        @data.default_proc = Key_Not_Found
      else
        @raw = unknown
        @raw.default_proc = Key_Not_Found
      end
    end

    if @raw
      self.class.on_doc.each { |raw_arr|

        conds = raw_arr.first
        func  = raw_arr.last
        instance_eval(&func) if conds.all? { |cond|
          case cond
          when Symbol
            send(cond)
          when Proc
            cond.arity == 1 ? cond.call(@raw) : instance_eval(&cond)
          when TrueClass, FalseClass
            cond
          else
            fail ArgumentError, "Unknown: #{cond.inspect}"
          end
        }

      } # === on_doc.each

      if !@clean
        @raw.each { |k, v|
          clean(k) if self.class.fields.has_key?(k)
        }
      end

      if create?
        self.class.fields.each { |k, meta|
          if !clean.has_key?(k) && !meta[:allow][:null] && !meta[:primary_key]
            fail ArgumentError, "#{k.inspect} is not set."
          end
        }
      end

      case
      when create?
        insert_into_table unless !respond_to?(:insert_into_table)
      when update?
        alter_record unless !respond_to?(:alter_record)
      when delete?
        delete_from_table unless !respond_to?(:delete_from_table)
      end unless @skips[:db]
    end # === if @raw

    self.class.schema_match(:all)
  end

  def skip name
    @skips[name] = true
  end

  def error?
    @error && !@error.empty?
  end

  def clean *args
    if args.empty?
      @clean ||= begin
                   h = {}
                   h.default_proc = Key_Not_Found
                   h
                 end
      return @clean
    end

    if args.size > 1
      return args.each { |f| clean f }
    end

    name     = args.first
    required = false

    if self.class.fields_as_required[name]
      name = self.class.fields_as_required[name]
      required = true
    end

    field_name(name)
    f_meta   = self.class.fields[name]
    required = true if (!field[:allow][:null] && (!@raw.has_key?(name) || @raw[name] == nil))

    # === Did the programmer forget to set the value?:
    if required && (!@raw.has_key?(name) || @raw[name].nil?)
      fail ArgumentError, "#{name.inspect} is not set."
    end

    # === Skip this if nothing is set and is null-able:
    if !required && field[:allow][:null] && !@raw.has_key?(name) && !clean.has_key?(name)
      return nil
    end

    clean[name] = @raw[name] unless clean.has_key?(name)

    # === Should we let the DB set the value?
    if self.class.schema[name] && self.class.schema[name][:default] && (!clean.has_key?(name) || !clean[name])
      clean.delete name
      return self.class.schema[name][:default]
    end

    # === Strip the value:
    if clean[name].is_a?(String) && field[:allow][:strip]
      clean[name].strip!
    end

    if field?(:chars) && !field.has_key?(:min) && clean[name].is_a?(String) && field[:allow][:null]
      clean[name] = nil
    end

    if field?(:numeric) && clean[name].is_a?(String)
      clean_val = Integer(clean[name]) rescue String
      if clean_val == String
        fail! "!English_name must be numeric."
      else
        clean[name] = clean_val
      end
    end

    if field?(:text) && clean[name].is_a?(String) && clean[name].empty? && field[:min].to_i > 0
      fail! "!English_name is required."
    end
    # ================================

    # === check min, max ======
    if clean[name].is_a?(String) || clean[name].is_a?(Numeric)
      case [field[:min], field[:max]].map(&:class)

      when [NilClass, NilClass]
        # do nothing

      when [NilClass, Fixnum]
        case
        when clean[name].is_a?(String) && clean[name].size > field[:max]
          fail! "!English_name can't be longer than !max characters."
        when clean[name].is_a?(Numeric) && clean[name] > field[:max]
          fail! "!English_name can't be higher than !max."
        end

      when [Fixnum, NilClass]
        case
        when clean[name].is_a?(String) && clean[name].size < field[:min]
          fail! "!English_name can't be shorter than !min characters."
        when clean[name].is_a?(Numeric) && clean[name] < field[:min]
          fail! "!English_name can't be less than !min."
        end

      when [Fixnum, Fixnum]
        case
        when clean[name].is_a?(String) && (clean[name].size < field[:min] || clean[name].size > field[:max])
          fail! "!English_name must be between !min and !max characters."
        when clean[name].is_a?(Numeric) && (clean[name] < field[:min] || clean[name] > field[:max])
          fail! "!English_name must be between !min and !max."
        end

      else
        fail "Unknown values for :min, :max: #{field[:min].inspect}, #{field[:max].inspect}"
      end
    end # === if
    # ================================

    # === to_i if necessary ==========
    if field?(:numeric)
      if clean[name].nil? && !field[:allow][:null]
        clean[name] = clean[name].to_i
      end
    end
    # ================================

    # === :strip if necessary ========
    if field?(:chars) && field[:allow][:strip] && clean[name].is_a?(String)
      clean[name] = clean[name].strip
    end
    # ================================

    # === Is value in options? =======
    if field[:options]
      if !field[:options].include?(clean[name])
        fail! "!English_name can only be: #{field[:options].map(&:inspect).join ', '}"
      end
    end
    # ================================

    field[:cleaners].each { |cleaner, args|
      next if args === false # === cleaner has been disabled.

        case cleaner

        when :type
          case
          when field?(:numeric) && !clean[name].is_a?(Integer)
            fail! "!English_name needs to be an integer."
          when field?(:chars) && !clean[name].is_a?(String)
            fail! "!English_name needs to be a String."
          end

        when :exact_size
          if clean[name].size != field[:exact_size]
            case
            when field?(:chars) || clean[name].is_a?(String)
              fail! "!English_name needs to be !exact_size in length."
            else
              fail! "!English_name can only be !exact_size in size."
            end
          end

        when :set_to
          args.each { |meth|
            clean[name] = send(meth)
          }

        when :equal_to
          args.each { |pair|
            meth, msg, other = pair
            target = send(meth)
            fail!(msg || "!English_name must be equal to: #{target.inspect}") unless clean[name] == target
          }

        when :included_in
          arr, msg, other = args
          fail!(msg || "!English_name must be one of these: #{arr.join ', '}") unless arr.include?(clean[name])

        when :upcase
          clean[name] = clean[name].upcase

        when :match
          args.each { |pair|
            regex, msg, other = pair
            if clean[name] !~ regex
              fail!(msg || "!English_name must match #{regex.inspect}")
            end
          }

        when :not_match
          args.each { |pair|
            regex, msg, other = pair
            if clean[name] =~ regex
              fail!(msg || "!English_name must not match #{regex.inspect}")
            end
          }

        else
          fail "Cleaner not implemented: #{cleaner.inspect}"
        end # === case cleaner
    } # === field[:cleaners].each
  end # === def clean

  def new_data
    @new_data ||= {}
  end

  def on *args
    fail ArgumentError, "No conditions." if args.empty?
    yield if args.all? { |cond|
      case cond
      when Symbol
        send(cond)
      when TrueClass, FalseClass
        cond
      else
        fail ArgumentError, "Unknown value: #{cond.inspect}"
      end
    }
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

    @error = {:field_name=>field_name, :msg=>err_msg, :value=>clean[field_name]}
    throw :invalid, self
  end

  def field_name *args
    case args.size
    when 0
      fail "Field name not set." unless @field_name
      @field_name
    when 1
      fail ArgumentError, "Unknown field: #{args.first.inspect}" unless self.class.fields[args.first]
      @field_name = args.first
    else
      fail "Unknown args: #{args.inspect}"
    end
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

  def primary_key
    arr = self.class.fields.detect { |k, v| v[:primary_key] }
    fail "Primary key not found." unless arr
    arr.last
  end

  def create?
    (@raw.has_key?(:create) && @raw[:create]) ||
    @raw.has_key?(primary_key[:name]) && !@raw[primary_key[:name]]
  end

  def read?
    !!(@raw.has_key?(:read) && @raw[:read])
  end

  def update?
    !!(@raw.has_key?(:update) && @raw[:update])
  end

  def delete?
    !!(@raw.has_key?(:delete) && !@raw[:delete])
  end

end # === module Datoki ===



