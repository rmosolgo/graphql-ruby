# frozen_string_literal: true
module GraphQL
  class Schema
    class Member
      # Wraps a {Schema::Member} when it is required.
      # @see {Schema::Member#to_non_null_type}
      # @api private
      class NonNullTypeProxy
        include GraphQL::Schema::Member::CachedGraphQLDefinition
        attr_reader :of_type
        def initialize(of_type)
          @of_type = of_type
        end

        def to_graphql
          @of_type.graphql_definition.to_non_null_type
        end

        def to_list_type
          ListTypeProxy.new(self)
        end
      end
    end
  end
end
