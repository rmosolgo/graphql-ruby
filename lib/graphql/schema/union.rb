# frozen_string_literal: true
module GraphQL
  class Schema
    class Union < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition

      class << self
        def possible_types(*types)
          if types.any?
            @possible_types = types
          else
            all_possible_types = @possible_types || []
            all_possible_types += super if defined?(super)
            all_possible_types.uniq
          end
        end

        def to_graphql
          type_defn = GraphQL::UnionType.new
          type_defn.name = graphql_name
          type_defn.description = description
          type_defn.possible_types = possible_types
          if respond_to?(:resolve_type)
            type_defn.resolve_type = method(:resolve_type)
          end
          type_defn.metadata[:type_class] = self
          type_defn
        end

        def kind
          GraphQL::TypeKinds::UNION
        end
      end
    end
  end
end
