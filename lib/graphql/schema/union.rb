# frozen_string_literal: true
module GraphQL
  class Schema
    class Union < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition

      class << self
        def possible_types(*types, context: GraphQL::Query::NullContext, **options)
          if types.any?
            types.each do |t|
              type_memberships << type_membership_class.new(self, t, options)
            end
          else
            visible_types = []
            type_memberships.each do |tv|
              if tv.visible?(context)
                visible_types << tv.object_type
              end
            end
            visible_types.uniq!
            visible_types
          end
        end

        def to_graphql
          type_defn = GraphQL::UnionType.new
          type_defn.name = graphql_name
          type_defn.description = description
          type_defn.type_memberships = type_memberships
          if respond_to?(:resolve_type)
            type_defn.resolve_type = method(:resolve_type)
          end
          type_defn.metadata[:type_class] = self
          type_defn
        end

        def type_membership_class(visibility_class = nil)
          if visibility_class
            @type_membership_class = visibility_class
          else
            @type_membership_class || find_inherited_value(:type_membership_class, GraphQL::Schema::TypeMembership)
          end
        end

        def kind
          GraphQL::TypeKinds::UNION
        end

        private

        def type_memberships
          @type_memberships ||= []
        end
      end
    end
  end
end
