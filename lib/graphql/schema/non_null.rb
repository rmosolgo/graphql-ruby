# frozen_string_literal: true

module GraphQL
  class Schema
    # Wraps a {Schema::Member} when it is required.
    # @see {Schema::Member::TypeSystemHelpers#to_non_null_type}
    class NonNull
      include GraphQL::Schema::Member::CachedGraphQLDefinition
      include GraphQL::Schema::Member::TypeSystemHelpers
      attr_reader :of_type
      def initialize(of_type)
        @of_type = of_type
      end

      def to_graphql
        @of_type.graphql_definition.to_non_null_type
      end

      # @return [true]
      def non_null?
        true
      end

      # @return [Boolean] True if this type wraps a list type
      def list?
        @of_type.list?
      end

      def kind
        GraphQL::TypeKinds::NON_NULL
      end

      def unwrap
        @of_type.unwrap
      end

      def to_type_signature
        "#{@of_type.to_type_signature}!"
      end
    end
  end
end
