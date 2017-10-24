# frozen_string_literal: true
module GraphQL
  module DeprecatedDSL
    refine GraphQL::SchemaMember.singleton_class do
      def !
        to_non_null_type
      end

      def to_list_type
        ListTypeProxy.new(self)
      end

      def to_non_null_type
        NonNullTypeProxy.new(self)
      end

      class ListTypeProxy
        include GraphQL::SchemaMember::CachedGraphQLDefinition

        def initialize(member)
          @member = member
        end

        def to_graphql
          @member.graphql_definition.to_list_type
        end
      end

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
end
