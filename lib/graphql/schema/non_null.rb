# frozen_string_literal: true

module GraphQL
  class Schema
    # Represents a non null type in the schema.
    # Wraps a {Schema::Member} when it is required.
    # @see {Schema::Member::TypeSystemHelpers#to_non_null_type}
    class NonNull < GraphQL::Schema::Wrapper
      def to_graphql
        @of_type.graphql_definition.to_non_null_type
      end

       # @return [GraphQL::TypeKinds::NON_NULL]
      def kind
        GraphQL::TypeKinds::NON_NULL
      end

      # @return [true]
      def non_null?
        true
      end

      # @return [Boolean] True if this type wraps a list type
      def list?
        @of_type.list?
      end

      def to_type_signature
        "#{@of_type.to_type_signature}!"
      end

      def inspect
        "#<#{self.class.name} @of_type=#{@of_type.inspect}>"
      end
    end
  end
end
