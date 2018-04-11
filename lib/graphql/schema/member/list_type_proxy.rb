# frozen_string_literal: true
module GraphQL
  class Schema
    class Member
      # Wraps a {Schema::Member} as a list type.
      # @see {Schema::Member#to_list_type}
      # @api private
      class ListTypeProxy
        include GraphQL::Schema::Member::CachedGraphQLDefinition

        attr_reader :of_type

        def initialize(of_type)
          @of_type = of_type
        end

        def to_graphql
          @of_type.graphql_definition.to_list_type
        end

        def to_non_null_type
          NonNullTypeProxy.new(self)
        end
      end
    end
  end
end
