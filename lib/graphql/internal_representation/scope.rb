# frozen_string_literal: true
module GraphQL
  module InternalRepresentation
    # At a point in the AST, selections may apply to one or more types.
    # {Scope} represents those types which selections may apply to.
    #
    # Scopes can be defined by:
    #
    # - A single concrete or abstract type
    # - An array of types
    # - `nil`
    #
    # The AST may be scoped to an array of types when two abstractly-typed
    # fragments occur in inside one another.
    class Scope
      NO_TYPES = [].freeze

      # @param query [GraphQL::Query]
      # @param type_defn [GraphQL::BaseType, Array<GraphQL::BaseType>, nil]
      def initialize(query, type_defn)
        @query = query
        @type = type_defn
        @abstract_type = false
        @types = case type_defn
        when Array
          type_defn
        when GraphQL::BaseType
          @abstract_type = true
          nil
        when nil
          NO_TYPES
        else
          raise "Unexpected scope type: #{type_defn}"
        end
      end

      # From a starting point of `self`, create a new scope by condition `other_type_defn`.
      # @param other_type_defn [GraphQL::BaseType, nil]
      # @return [Scope]
      def enter(other_type_defn)
        case other_type_defn
        when nil
          # The type wasn't found, who cares
          Scope.new(@query, nil)
        when @type
          # The condition is the same as current, so reuse self
          self
        when GraphQL::UnionType, GraphQL::InterfaceType
          # Make a new scope of the intersection between the previous & next conditions
          new_types = @query.possible_types(other_type_defn) & concrete_types
          Scope.new(@query, new_types)
        when GraphQL::BaseType
          # If this type is valid within the current scope,
          # return a new scope of _exactly_ this type.
          # Otherwise, this type is out-of-scope so the scope is null.
          if concrete_types.include?(other_type_defn)
            Scope.new(@query, other_type_defn)
          else
            Scope.new(@query, nil)
          end
        else
          raise "Unexpected scope: #{other_type_defn.inspect}"
        end
      end

      # Call the block for each type in `self`.
      # This uses the simplest possible expression of `self`,
      # so if this scope is defined by an abstract type, it gets yielded.
      def each(&block)
        if @abstract_type
          yield(@type)
        else
          @types.each(&block)
        end
      end

      private

      def concrete_types
        @concrete_types ||= if @abstract_type
          @query.possible_types(@type)
        else
          @types
        end
      end
    end
  end
end
