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

        @storage = Hash.new do |hash, key|
          hash[key] = @object_types.select { |type| type.interfaces.include?(key) }.sort_by(&:name)
        end
      end

      def possible_types(type_defn)
        case type_defn
        when GraphQL::UnionType
          type_defn.possible_types
        when GraphQL::InterfaceType
          @storage[type_defn]
        when GraphQL::ObjectType
          [type_defn]
        else
          []
        end
      end
    end
  end
end
