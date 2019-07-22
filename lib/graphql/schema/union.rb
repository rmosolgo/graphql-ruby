# frozen_string_literal: true
module GraphQL
  class Schema
    class Union < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition

      class << self
        def possible_types(*types, ctx: nil)
          if types.any?
            @possible_types = types
          else
            all_possible_types = @possible_types || []
            all_possible_types += super if defined?(super)
            ctx ? filter_possible_types(all_possible_types.uniq, ctx) : all_possible_types.uniq
          end
        end

        def to_graphql
          type_defn = GraphQL::UnionType.new
          type_defn.name = graphql_name
          type_defn.description = description
          type_defn.possible_types = possible_types
          type_defn.filter_possible_types = method(:filter_possible_types)
          if respond_to?(:resolve_type)
            type_defn.resolve_type = method(:resolve_type)
          end
          type_defn.metadata[:type_class] = self
          type_defn
        end

        def kind
          GraphQL::TypeKinds::UNION
        end

        # Filter possible type based on the current context, no-op by default
        # @param types [Array<GraphQL::ObjectType>] Types to be filtered
        # @param ctx [GraphQL::Query::Context] The context for the current query
        # @param [Array<GraphQL::ObjectType>] the types remaining after the filter is applied
        def filter_possible_types(types, ctx)
          types
        end
      end
    end
  end
end
