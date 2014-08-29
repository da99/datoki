
module Okdoki
  module Model

    #
    # Example:
    #
    #    class My_List
    #      include Okdoki::Model::List
    #
    #      def initialize *args
    #        do magic
    #      end
    #
    #      def list
    #        @list ||= begin
    #                    Load list
    #                  end
    #      end
    #
    #    end
    #
    #    class Customer
    #      def initialize
    #        @my_list = My_List.new(self)
    #      end
    #
    #
    module List

      include ::Enumerable


      def pluck key
        list.map { |n| n.data[key] }
      end

      def each
        list.each { |n| yield n }
      end

      def push *args
        list.concat args.flatten
        list
      end

    end # === module Enumerable ===
  end # === module Model ===
end # === module Okdoki ===
