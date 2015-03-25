
require 'sequel'

module Datoki

  UTC_NOW_DATE = ::Sequel.lit("CURRENT_DATE")
  UTC_NOW_RAW  = "timezone('UTC'::text, now())"
  UTC_NOW      = ::Sequel.lit("timezone('UTC'::text, now())")

  Invalid         = Class.new RuntimeError
  Schema_Conflict = Class.new RuntimeError

  Actions       = [:all, :create, :read, :update, :update_or_create, :trash, :delete]
  Char_Types    = [:varchar, :text, :string_ish]
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

    attr_reader :ons, :fields, :table_name, :fields_as_required

    def initialize_def_field
      @ons                = {}
      @fields             = {} # Ex: {:name=>{}, :age=>{}}
      @fields_as_required = {} # Ex: {:name!=>:name}
      @current_field      = nil
      @schema             = {}
      @schema_match       = false
      @table_name         = nil
    end

    def schema_match?
      @schema_match
    end

    def table name
      fail ArgumentError, "Table name must be a Symbol: #{name.inspect}" unless name.is_a?(Symbol)
      if !@schema.empty? || @table_name
        fail "Schema/table already defined: #{@table_name.inspect}"
      end

      db_schema = Datoki.db.schema(name)

      if !db_schema
        fail ArgumentError, "Schema not found for: #{name.inspect}"
      end

      @table_name = name
      self.const_set(:TABLE, DB[@table_name])

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

    def pseudo
      fields[@current_field][:pseudo] = true
    end

    def allow sym
      fields[@current_field][:allow][sym] = true;
    end

    def field? *args
      inspect_field?(:type, field[:name], *args)
    end

    def field *args
      # === Setup a default table if none specified:
      if !@table_name && Datoki.db
        t_name = self.to_s.downcase.to_sym
        table(t_name) if Datoki.db.tables.include?(t_name)
      end

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

      return true if db_schema && !field
      return true if field[:schema_has_been_matched]
      return true if field[:pseudo]

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
      if field[:type] != :string_ish
        db_type = Datoki.db_type_to_ruby db_schema[:db_type], db_schema[:type]
        type    = field[:type]
        if db_type != type
          fail Schema_Conflict, "#{name}: :type: #{db_type.inspect} != #{type.inspect}"
        end
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

      field[:schema_has_been_matched] = true
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

    def unique_index name, msg = nil
      field[:unique_index] = name
      if msg
        field[:error_msgs] ||= {}
        field[:error_msgs][:unique] = msg
      end
      self
    end

    def secret
      field[:secret] = true
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

      when [Proc], [Regexp]
        matches *args

      when [Fixnum, Fixnum, Proc], [Fixnum, Fixnum, Regexp]
        field[:min] = args.shift
        field[:max] = args.shift
        matches *args

      else
        fail "Unknown args: #{args.inspect}"

      end # === case

    end # === def

    [:mis_match, :small, :big].each { |name|
      eval <<-EOF
        def #{name} msg
          field[:error_msgs] ||= {}
          field[:error_msgs][:#{name}] = msg
        end
      EOF
    }

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

    def set_to v = :blok
      field[:cleaners][:set_to] ||= []
      field[:cleaners][:set_to] << (v == :blok ? Proc.new : v)
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

    def matches v = :blok
      field[:cleaners][:match] ||= []
      field[:cleaners][:match] << (v == :blok ? Proc.new : v)
    end

    def create raw
      raw[:create] = self
      new raw
    end

  end # === Def_Field =====================================================

  # ================= Instance Methods ===============

  attr_reader :error, :data, :raw
  def initialize unknown = nil
    @data       = nil
    @field_name = nil
    @clean      = nil
    @error      = nil
    @skips      = {}
    @db_ops     = {} # Ex: :db_insert=>true, :db_update=>true

    if unknown
      if unknown.keys.all? { |f| self.class.fields.has_key?(f) }
        @data = unknown
        @data.default_proc = Key_Not_Found
      else
        @raw = unknown
      end
    end

    if @raw

      schema = self.class.schema

      case
      when create? && respond_to?(:create)
        create
      when update? && respond_to?(:update)
        update
      when delete? && respond_to?(:delete)
        delete
      end

      if @clean
        @clean.each { |k, v|
          # === Delete nil value if schema has a default value:
          @clean.delete(k) if @clean[k].nil? && schema[k] && schema[k][:default]
        }
      end

      fail "No clean values found." if (!@clean || @clean.empty?)

      if !@skips[:db] && !self.class.schema.empty?

        final = db_clean
        begin
          case

          when create?
            db_insert

          when update?

            DB[self.class.table].
              where(primary_key[:name] => final.delete(primary_key[:name])).
              update(final)

          when delete?
            DB[self.class.table].
              where(primary_key[:name] => final.delete(primary_key[:name])).
              delete

          end

        rescue Sequel::UniqueConstraintViolation => e

          self.class.fields.each { |f, meta|
            if meta[:unique_index] && e.message[%^unique constraint "#{meta[:unique_index]}"^]
              field_name f
              fail! :unique, "{{English name}} already taken: #{final[f]}"
            end
          }
          raise e

        end # === begin/rescue
      end # === if !@skips[:db]
    end # === if @raw
  end

  def skip name
    @skips[name] = true
  end

  def error?
    @error && !@error.empty?
  end

  def db_clean
    @clean.select { |k, v|
      meta = self.class.fields[k]
      !meta || !meta[:pseudo]
    }
  end

  def clean! *args
    args.each { |name|
      if @raw[name].nil? && (!@clean || @clean[name].nil?)
        fail ArgumentError, "#{name.inspect} is not set."
      else
        clean name
      end
    }
  end

  def clean *args
    @clean ||= {}

    return @clean if args.empty?

    # === Handle required fields:
    # Example:
    #   :name!, :age!
    if args.size > 1
      return args.each { |f| clean f }
    end

    name = args.first

    if (real_name = self.class.fields_as_required[name])
      return(clean! real_name) 
    end

    @clean[name] = @raw[name] if !clean.has_key?(name) && @raw.has_key?(name)

    # === Skip cleaning if key is not set:
    return nil unless @clean.has_key?(name)

    field_name(name)
    f_meta = self.class.fields[name]

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
        fail! :wrong_type, "{{English name}} must be numeric."
      else
        clean[name] = clean_val
      end
    end

    if field?(:text) && clean[name].is_a?(String) && clean[name].empty? && field[:min].to_i > 0
      fail! :required, "{{English name}} is required."
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
          fail! :big, "{{English name}} can't be longer than {{max}} characters."
        when clean[name].is_a?(Numeric) && clean[name] > field[:max]
          fail! :big, "{{English name}} can't be higher than {{max}}."
        end

      when [Fixnum, NilClass]
        case
        when clean[name].is_a?(String) && clean[name].size < field[:min]
          fail! :short, "{{English name}} can't be shorter than {{min}} characters."
        when clean[name].is_a?(Numeric) && clean[name] < field[:min]
          fail! :short, "{{English name}} can't be less than {{min}."
        end

      when [Fixnum, Fixnum]
        case
        when field?(:chars) && clean[name].size > field[:max]
          fail! :big, "{{English name}} must be between {{min}} and {{max}} characters."
        when field?(:chars) && clean[name].size < field[:min]
          fail! :small, "{{English name}} must be between {{min}} and {{max}} characters."

        when field?(:numeric) && clean[name] > field[:max]
          fail! :big, "{{English name}} must be between {{min}} and {{max}}."
        when field?(:numeric) && clean[name] < field[:min]
          fail! :small, "{{English name}} must be between {{min}} and {{max}}."
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
        fail! :mis_match, "{{English name}} can only be: #{field[:options].map(&:inspect).join ', '}"
      end
    end
    # ================================

    field[:cleaners].each { |cleaner, args|
      next if args === false # === cleaner has been disabled.

        case cleaner

        when :type
          case
          when field?(:numeric) && !clean[name].is_a?(Integer)
            fail! :wrong_type, "{{English name}} needs to be an integer."
          when field?(:chars) && !clean[name].is_a?(String)
            fail! :wrong_type, "{{English name}} needs to be a String."
          end

        when :exact_size
          if clean[name].size != field[:exact_size]
            case
            when field?(:chars) || clean[name].is_a?(String)
              fail! :mis_match, "{{English name}} needs to be {{exact_size}} in length."
            else
              fail! :mis_match, "{{English name}} can only be {{exact_size}} in size."
            end
          end

        when :set_to
          args.each { |meth|
            clean[name] = (meth.is_a?(Symbol) ? send(meth) : meth.call(self, clean[name]))
          }

        when :equal_to
          args.each { |pair|
            meth, msg, other = pair
            target = send(meth)
            fail!(msg || "{{English name}} must be equal to: #{target.inspect}") unless clean[name] == target
          }

        when :included_in
          arr, msg, other = args
          fail!(msg || "{{English name}} must be one of these: #{arr.join ', '}") unless arr.include?(clean[name])

        when :upcase
          clean[name] = clean[name].upcase

        when :match
          args.each { |regex|
            case regex
            when Regexp
              if clean[name] !~ regex
                fail!(:mis_match, "{{English name}} is invalid.")
              end

            when Proc
              if !regex.call(self, clean[name])
                fail!(:mis_match, "{{English name}} is invalid.")
              end

            else
              fail ArgumentError, "Unknown matcher: #{regex.inspect}"
            end
          }

        else
          fail "Cleaner not implemented: #{cleaner.inspect}"
        end # === case cleaner
    } # === field[:cleaners].each
  end # === def clean

  def error_msg type
    field[:error_msgs] && field[:error_msgs][type]
  end

  def fail! *args
    case args.size
    when 1
      msg = args.shift
    when 2
      msg = error_msg(args.shift) || args.shift
    else
      fail ArgumentError, "Unknown args: #{args.inspect}"
    end

    err_msg = msg.gsub(/\{\{([a-z\_\-\ ]+)\}\}/i) { |raw|
      name = $1
      case name
      when "English name"
        self.class.fields[field_name][:english_name].capitalize.gsub('_', ' ')
      when "ENGLISH NAME"
        self.class.fields[field_name][:english_name].upcase.gsub('_', ' ')
      when "max", "min", "exact_size"
        self.class.fields[field_name][name.downcase.to_sym]
      when "val"
        clean[field_name]
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

  def primary_key
    arr = self.class.fields.detect { |k, v| v[:primary_key] }
    fail "Primary key not found." unless arr
    arr.last
  end

  def new?
    !@data
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

  def TABLE
    self.class::TABLE
  end

  def returning_fields
    table_name = self.class.table_name
    return [] unless table_name
    s = Datoki.db.schema(table_name)
    return [] unless s
    s.map { |pair|
      name, meta = pair
      field = self.class.fields[name]
      if !field || !field[:secret]
        name
      else
        nil
      end
    }.compact
  end

  def db_insert
    k = :db_insert
    final = db_clean
    fail "Already inserted." if @db_ops[k]
    @data = (@data || {}).merge(TABLE().returning(*returning_fields).insert(final).first)
    @db_ops[k] = true
  end

end # === module Datoki ===



