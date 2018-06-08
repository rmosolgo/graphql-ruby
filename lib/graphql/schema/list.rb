# frozen_string_literal: true

module GraphQL
  class Schema
    # Represents a list type in the schema.
    # Wraps a {Schema::Member} as a list type.
    # @see {Schema::Member::TypeSystemHelpers#to_list_type}
    class List
      include GraphQL::Schema::Member::CachedGraphQLDefinition
      include GraphQL::Schema::Member::TypeSystemHelpers

      # @return [Class, Module] The inner type of this list, the type of which one or more objects may be present.
      attr_reader :of_type

      def initialize(of_type)
        @of_type = of_type
      end

      def to_graphql
        @of_type.graphql_definition.to_list_type
      end

      def kind
        GraphQL::TypeKinds::LIST
      end

      def unwrap
        @of_type.unwrap
      end

      def list?
        true
      end

      def to_type_signature
        "[#{@of_type.to_type_signature}]"
      end
    end
  end
end
