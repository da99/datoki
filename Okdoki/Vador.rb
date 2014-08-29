module Okdoki


  #
  # Examples:
  #
  #   Okdoki::Vador.new(self, :producer_id, raw).
  #     set_to_integer.
  #     data
  #
  #
  #   Okdoki::Vador.new(self, :consumer_id, raw).
  #     set_to_integer.
  #     data
  #
  class Vador

    class << self # =====================================

      def new o, name, new_data

        # Symbol-ify the key name
        str_name = name.to_s
        if new_data.has_key?(str_name)
          new_data[name] = new_data[str_name]
          new_data.delete(str_name)
        end

        # If key/value exist, proceed normally.
        # else, create special dummy validator.
        if new_data.has_key?(name)
          super o, name, new_data
        else
          Okdoki::Vador_Empty.new(o, name, new_data)
        end
      end

    end # === class self ================================

    attr_reader :model, :name, :english_name

    def initialize model, raw_name, raw_data
      @model           = model
      @name            = raw_name
      str_name         = @name.to_s
      @english_name    = str_name.capitalize.gsub('_', ' ')
      @clean_data      = raw_data.dup

      # === Force key to be a symbol:
      if data.has_key?(str_name)
        data[@name]= data[str_name]
        data.delete(str_name)
      end
    end

    def data
      @clean_data
    end

    def invalid_new msg = nil
      model.class::Invalid.new(model, msg || "#{@english_name} is invalid.")
    end

    #
    # Applies only to Strings or Arrays.
    # Ensures value has been set and not:
    #   String.strip.empty? && Array.empty?
    #
    def required msg = nil
      val = data[name]
      is_empty = !val || (val.kind_of?(String) && val.strip.empty?) || (val.respond_to?(:empty?) && val.empty?)
      raise invalid_new(msg || "#{english_name} is required." ) if is_empty

      self
    end

    # ===================================================
    IGNORE_METHODS = self.public_instance_methods
    # ===================================================

    #
    # Accepts: a lambda that must return TRUE or FALSE
    def be l, msg
      raise invalid_new(msg) unless (!! l.call(data[name]))
      self
    end

    def clean *args
      args.each { |a|
        case a.to_s
        when 'strip'
          data[name] = (data[name] || "").strip
        when 'upcase'
          data[name] = data[name].upcase
        when 'to_i'
          data[name] = data[name].to_i
        else
          raise "Unknown operation for :clean : #{a}"
        end
      }

      self
    end # === def

    def at_most val, msg
      raise invalid_new(msg) if data[name].size > val
      self
    end

    def at_least val, msg
      raise invalid_new(msg) if data[name].size < val
      self
    end

    def set_to val, func = nil
      if func
        (data[name] = val) if func.call(data[name])
      else
        data[name] = val
      end

      self
    end

    def set_to_integer msg = nil
      data[name] = begin
                     Integer data[name]
                    rescue ArgumentError => e
                      raise invalid_new(msg || "Integer required: #{data[name].inspect}")
                    end
      self
    end

    def equals val, msg
      raise invalid_new(msg) if data[name] != val
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
        raise invalid_new(msg) if data[name].match(p)
      }

      self
    end

    def in arr, msg = nil
      raise invalid_new(msg) unless arr.include?(data[name])
      self
    end

    def match pats, msg = nil
      if !pats.kind_of? Array
        pats = [pats]
      end

      pats.each { |p|
        raise invalid_new(msg) unless data[name].match(p)
      }
      self
    end

    def one_of_these arr, msg
      raise invalid_new(msg) unless arr.index(data[name])
      self
    end

  end # === class Vador

  class Vador_Empty

    meths = Vador.public_instance_methods - Vador::IGNORE_METHODS

    meths.each { |meth|
      class_eval %!
        def #{meth} *args
          self
        end
      !
    }

    def initialize model, name, data = {}
      @model = model
      @name  = name
      @clean_data = data
      super()
    end

    def required msg = nil
      raise @model::Invalid.new(@model, msg || "#{@name} is required.")
    end

  end # === class Vador_Empty

end # === module Okdoki

