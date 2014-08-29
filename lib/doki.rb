
module Doki

  Invalid = Class.new RuntimeError
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
    end

    def fields
      @fields
    end

    def field name
      @current_field = name
      @fields[@current_field] = {}
      yield
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

  end # === Def_Field

  # ================= Instance Methods ===============

  def initialize
    @new_data = {}
    super
  end

  def new_data h
    @new_data = h
  end

  def create
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

end # === module Doki ===
