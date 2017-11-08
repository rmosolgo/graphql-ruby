# frozen_string_literal: true
module GraphQL
  class SchemaMember
    # Wraps a {SchemaMember} as a list type.
    # @see {SchemaMember#to_list_type}
    # @api private
    class ListTypeProxy
      include GraphQL::SchemaMember::CachedGraphQLDefinition

      def initialize(member)
        @member = member
      end

      def to_graphql
        @member.graphql_definition.to_list_type
      end
    end
  end
end