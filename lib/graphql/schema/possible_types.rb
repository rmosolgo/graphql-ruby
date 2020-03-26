# frozen_string_literal: true
module GraphQL
  class Schema
    # Find the members of a union or interface within a given schema.
    #
    # (Although its members never change, unions are handled this way to simplify execution code.)
    #
    # Internally, the calculation is cached. It's assumed that schema members _don't_ change after creating the schema!
    #
    # @example Get an interface's possible types
    #   possible_types = GraphQL::Schema::PossibleTypes(MySchema)
    #   possible_types.possible_types(MyInterface)
    #   # => [MyObjectType, MyOtherObjectType]
    class PossibleTypes
      def initialize(schema)
        @object_types = schema.types.values.select { |type| type.kind.object? }
        @interface_implementers = Hash.new do |h1, ctx|
          h1[ctx] = Hash.new do |h2, int_type|
            h2[int_type] = @object_types.select { |type| type.interfaces(ctx).include?(int_type) }.sort_by(&:name)
          end
        end
      end

      def possible_types(type_defn, ctx)
        case type_defn
        when Module
          possible_types(type_defn.graphql_definition, ctx)
        when GraphQL::UnionType
          type_defn.possible_types(ctx)
        when GraphQL::InterfaceType
          interface_implementers(ctx, type_defn)
        when GraphQL::BaseType
          [type_defn]
        else
          raise "Unexpected possible_types object: #{type_defn.inspect}"
        end
      end

      def interface_implementers(ctx, type_defn)
        @interface_implementers[ctx][type_defn]
      end
    end
  end
end
