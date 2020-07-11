# frozen_string_literal: true
module GraphQL
  class Schema
    class Union < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition
      extend GraphQL::Schema::Member::HasUnresolvedTypeError

      class << self
        def inherited(child_class)
          add_unresolved_type_error(child_class)
          super
        end

        def possible_types(*types, context: GraphQL::Query::NullContext, **options)
          if types.any?
            types.each do |t|
              assert_valid_union_member(t)
              type_memberships << type_membership_class.new(self, t, **options)
            end
          else
            visible_types = []
            type_memberships.each do |type_membership|
              if type_membership.visible?(context)
                visible_types << type_membership.object_type
              end
            end
            visible_types
          end
        end

        def to_graphql
          type_defn = GraphQL::UnionType.new
          type_defn.name = graphql_name
          type_defn.description = description
          type_defn.ast_node = ast_node
          type_defn.type_memberships = type_memberships
          if respond_to?(:resolve_type)
            type_defn.resolve_type = method(:resolve_type)
          end
          type_defn.metadata[:type_class] = self
          type_defn
        end

        def type_membership_class(membership_class = nil)
          if membership_class
            @type_membership_class = membership_class
          else
            @type_membership_class || find_inherited_value(:type_membership_class, GraphQL::Schema::TypeMembership)
          end
        end

        def kind
          GraphQL::TypeKinds::UNION
        end

        def type_memberships
          @type_memberships ||= []
        end

        # Update a type membership whose `.object_type` is a string or late-bound type
        # so that the type membership's `.object_type` is the given `object_type`.
        # (This is used for updating the union after the schema as lazily loaded the union member.)
        # @api private
        def assign_type_membership_object_type(object_type)
          assert_valid_union_member(object_type)
          type_memberships.each { |tm|
            possible_type = tm.object_type
            if possible_type.is_a?(String) && (possible_type == object_type.name)
              # This is a match of Ruby class names, not graphql names,
              # since strings are used to refer to constants.
              tm.object_type = object_type
            elsif possible_type.is_a?(LateBoundType) && possible_type.graphql_name == object_type.graphql_name
              tm.object_type = object_type
            end
          }
          nil
        end

        private

        def assert_valid_union_member(type_defn)
          if type_defn.is_a?(Module) && !type_defn.is_a?(Class)
            # it's an interface type, defined as a module
            raise ArgumentError, "Union possible_types can only be object types (not interface types), remove #{type_defn.graphql_name} (#{type_defn.inspect})"
          end
        end
      end
    end
  end
end
