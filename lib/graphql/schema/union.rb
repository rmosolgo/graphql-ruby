# frozen_string_literal: true
module GraphQL
  class Schema
    class Union < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition

      class << self
        def possible_types(*types, ctx: GraphQL::Query::NullContext)
          if types.any?
            @possible_types = types
          else
            all_possible_types = @possible_types || []
            all_possible_types += super if defined?(super)
            filter_possible_types(all_possible_types.uniq, ctx)
          end
        end

        def to_graphql
          type_defn = GraphQL::UnionType.new
          type_defn.name = graphql_name
          type_defn.description = description
          type_defn.possible_types = possible_types
          type_defn.filtered_possible_types = method(:filtered_possible_types)
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
        # @param ctx [GraphQL::Query::Context] The context for the current query
        # @return [Array<GraphQL::ObjectType>] the types to filter from possible_types
        def filtered_possible_types(_ctx)
          []
        end

        def filter_possible_types(types, ctx)
          types_to_filter = filtered_possible_types(ctx).map { |type| GraphQL::BaseType.resolve_related_type(type) }

          types.delete_if { |type| types_to_filter.include?(GraphQL::BaseType.resolve_related_type(type)) }
        end
      end
    end
  end
end
