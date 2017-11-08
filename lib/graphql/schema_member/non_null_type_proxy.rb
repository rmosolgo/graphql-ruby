# frozen_string_literal: true
module GraphQL
  class SchemaMember
    # Wraps a {SchemaMember} when it is required.
    # @see {SchemaMember#to_non_null_type}
    # @api private
    class NonNullTypeProxy
      include GraphQL::SchemaMember::CachedGraphQLDefinition

      def initialize(member)
        @member = member
      end

      def to_graphql
        @member.graphql_definition.to_non_null_type
      end
    end
  end
end