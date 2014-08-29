
module Okdoki

  class Validate

    attr_reader :model, :name, :english_name, :clean_data

    class << self

      def new model, name
        s_name = name.to_s
        new_data = model.new_data
        if new_data.has_key?(s_name)
          new_data[name] = new_data[s_name]
          new_data.delete(s_name)
        end

        if new_data.has_key?(name)
          super model, name
        else
          Okdoki::Validate_Empty.new(model, name)
        end
      end

    end # === class self ===

    def initialize model, name
      @e               = model.class::Invalid
      @model           = model
      @name            = name
      @english_name    = @name.to_s.capitalize.gsub('_', ' ')
      @clean_data      = model.clean_data
      key = if model.new_data.has_key?(name.to_s)
              name.to_s
            else
              name
            end

      @clean_data[name]= model.new_data[key]
    end

    def e msg = nil
      @e.new(model, msg || "#{@english_name} is invalid.")
    end

    #
    # Applies only to Strings or Arrays.
    # Ensures value has been set and not:
    #   String.strip.empty? && Array.empty?
    #
    def required msg = nil
      val = clean_data[name]
      is_empty = !val || (val.kind_of?(String) && val.strip.empty?) || (val.respond_to?(:empty?) && val.empty?)
      raise e(msg || "#{english_name} is required." ) if is_empty

      self
    end

    IGNORE_METHODS = self.public_instance_methods

    def be l, msg
      result = !! l.call(clean_data[name])
      raise e(msg) unless result
      self
    end

    def clean *args
      args.each { |a|
        case a
        when 'strip'
          clean_data[name] = (clean_data[name] || "").strip
        when 'upcase'
          clean_data[name] = clean_data[name].upcase
        when 'to_i'
          clean_data[name] = clean_data[name].to_i
        else
          raise "Unknown clean: #{a}"
        end
      }

      self
    end # === def

    def at_most val, msg
      raise e(msg) if clean_data[name].size > val
      self
    end

    def at_least val, msg
      raise e(msg) if clean_data[name].size < val
      self
    end

    def set_to val, func = nil
      if func
        (clean_data[name] = val) if func.call(clean_data[name])
      else
        clean_data[name] = val
      end

      self
    end

    def equals val, msg
      raise e(msg) if clean_data[name] != val
      self
    end

    def set_to_nil_if_empty val
      set_to(nil, lambda { |v|
        if v.kind_of? String
          v.strip.size == 0
        else
          v.size == 0
        end
      })
    end

    def not_match pats, msg = nil
      if !pats.kind_of? Array
        pats = [pats]
      end

      pats.each { |p|
        raise e(msg) if model.clean_data[name].match(p)
      }

      self
    end

    def in arr, msg = nil
      raise e(msg) unless arr.include?(clean_data[name])
      self
    end

    def match pats, msg = nil
      if !pats.kind_of? Array
        pats = [pats]
      end

      pats.each { |p|
        raise e(msg) unless model.clean_data[name].match(p)
      }
      self
    end

    def one_of_these arr, msg
      raise e(msg) unless arr.index(model.clean_data[name])
      self
    end

  end # === class Validate

  class Validate_Empty

    meths = Validate.public_instance_methods - Validate::IGNORE_METHODS

    meths.each { |meth|
      case meth
      when :required
      else
        class_eval %!
          def #{meth} *args
            self
          end
        !
      end
    }

    def initialize model, name
      super()
    end

  end # === class Validate_Empty

end # === module Okdoki












