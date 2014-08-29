require 'sequel'
DB = Sequel.connect(ENV['DATABASE_URL'])

require './Server/Okdoki/Validate'
require './Server/Okdoki/helpers/Helpers'
require './Server/Okdoki/List'
require './Server/Okdoki/PG'


CRUD_Actions = [:create, :read, :update, :trash, :delete, :up_create, :read_create]

def require_crud *klasses
  klasses.each do |klass|
    CRUD_Actions.each { |action|
      begin
        file = "./Server/#{klass}/model/#{action}"
        require file
      rescue LoadError => e
        raise e unless e.message["cannot load such file -- #{file}"]
      end
    }
  end
end

module Okdoki

  # =====================================================
  # Errors
  # =====================================================

  class Invalid < RuntimeError

    attr_reader :model, :msg

    def initialize o, msg
      @model = o
      @msg   = msg
      super(msg)
    end

  end # === class Invalid ===

  class Limit_Reached < RuntimeError

    attr_reader :model, :msg

    def initialize o, msg
      @model = o
      @msg   = msg
      super(msg)
    end

  end # === class Limit_Reached

  class Not_Found < RuntimeError

    attr_reader :msg

    def initialize msg = nil
      if !msg
        msg = "Not found."
      elsif !msg.kind_of? String
        msg = "#{msg.class} not found."
      end
      @msg = msg
      super(@msg)
    end

  end # === class Not_Found ===

  # =====================================================
  # Helpers
  # =====================================================

  class << self
  end # === class self ===

  # =====================================================
  # Modules
  # =====================================================

  module Model_Extend

    def new *args
      if args.size == 1 && args.first.is_a?(Array)
        args.first.map { |r|
          super(r)
        }
      else
        super
      end
    end

    def okdoki_id
      case self.name
      when Customer.name
        1
      when Screen_Name.name
        2
      else
        raise ":okdoki_id not set for #{self}"
      end
    end

    def table_name
      @table_name ||= "#{self.name.downcase}"
    end

    def table
      @table ||= DB[table_name]
    end

    def empty_trash
      self::TABLE.
        returning.
        where("trashed_at <= (timezone('UTC'::text, now()) - interval '72 hours')").
        delete
    end

    def english_name
      self.to_s.gsub('_', ' ')
    end

  end # === module Model_Extend ===

  # =====================================================
  # Model (the main stuff)
  # =====================================================

  module Model

    attr_reader :data, :new_data

    class << self

      def included klass
        klass.extend Model_Extend
        klass.const_set :Not_Found     , Class.new(Not_Found)
        klass.const_set :Invalid       , Class.new(Invalid)
        klass.const_set :Limit_Reached , Class.new(Limit_Reached)
      end

    end # === class self ===

    def validate name
      @spec = name
      Okdoki::Validate.new(self, name)
    end

    def initialize *args
      clear_cache
      @clean_data = {}
      @new_data   = {}

      return @data = {} if args.empty?
      return @data = args.first if args.first

      # === record was not found
      raise self.class::Not_Found.new(args.last || "#{self.class.english_name} not found.")
    end

    def id
      data[:id]
    end

    def trash
      alter_trash :in
    end

    def untrash
      alter_trash :out
    end

    def alter_trash into_trash
      key =  self.class::TRASH_KEY
      val = into_trash == :in ? Sequel.lit("timezone('UTC'::text, now())") : nil
      row = self.class::TABLE.
        returning.
        where( key => data[key] ).
        update(:trashed_at => val).
        first
      @data.merge!( row ) if row
      self
    end

    def clear_cache
      @cache = {}
    end

    def cache *args
      @cache ||= {}
      case args.size
      when 0
        raise "Not enough args."
      when 1
        @cache[args.first]
      when 2
        @cache[args.first] = args.last
        args.last
      else
        raise "Too many args: #{args.inspect}"
      end
    end

  end # === module Model ===

end # === module Okdoki ===

require './Server/Okdoki/Ancestor_Sql'













