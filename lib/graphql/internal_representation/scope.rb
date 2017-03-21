# frozen_string_literal: true
module GraphQL
  module InternalRepresentation
    class Scope
      attr_reader :types
      def initialize(query, type_defn)
        @query = query
        @type = type_defn
        @one_type = false
        @types = case type_defn
        when Set
          type_defn
        when GraphQL::BaseType
          @one_type = true
          @query.possible_types_set(type_defn)
        when nil
          Set.new
        else
          raise "Unexpected scope type: #{type_defn}"
        end
      end

      def enter(other_type_defn)
        if other_type_defn == @type
          self
        elsif other_type_defn.nil?
          self.replace(nil)
        else
          new_types = @query.possible_types_set(other_type_defn) & @types
          self.replace(new_types)
        end
      end

      def replace(new_type)
        self.class.new(@query, new_type)
      end

      def each
        if @one_type
          yield(@type)
        else
          @types.each { |t| yield(t) }
        end
      end
    end
  end
end
