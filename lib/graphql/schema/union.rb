# frozen_string_literal: true
module GraphQL
  class Schema
    class Union < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition

      class << self
        def possible_types(*types, ctx: GraphQL::Query::NullContext, visibility: nil)
          if types.any?
            @type_visibilities ||= []
            @type_visibilities << type_visibility_class.new(types, visibility)
          else
            @type_visibilities.reduce([]) do |types, membership_visibility|
              membership_visibility.visible?(ctx) ? types + membership_visibility.types : types
            end.uniq
          end
        end

        def to_graphql
          type_defn = GraphQL::UnionType.new
          type_defn.name = graphql_name
          type_defn.description = description
          type_defn.type_visibilities = @type_visibilities || []
          if respond_to?(:resolve_type)
            type_defn.resolve_type = method(:resolve_type)
          end
          type_defn.metadata[:type_class] = self
          type_defn
        end

        def type_visibility_class(visibility_class = nil)
          if visibility_class
            @type_visibility_class = visibility_class
          else
            @type_visibility_class || find_inherited_value(:type_visibility_class, GraphQL::Schema::TypeMembership)
          end
        end

        def kind
          GraphQL::TypeKinds::UNION
        end
      end
    end
  end
end
