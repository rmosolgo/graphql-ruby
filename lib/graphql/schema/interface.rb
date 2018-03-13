# frozen_string_literal: true
module GraphQL
  class Schema
    class Interface < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::HasFields
      field_class GraphQL::Schema::Field

      class << self
        # When this interface is added to a `GraphQL::Schema::Object`,
        # it calls this method. We add methods to the object by convention,
        # a nested module named `Implementation`
        def apply_implemented(object_class)
          if defined?(self::Implementation)
            object_class.include(self::Implementation)
          end
        end

        def orphan_types(*types)
          if types.any?
            @orphan_types = types
          else
            all_orphan_types = @orphan_types || []
            all_orphan_types += super if defined?(super)
            all_orphan_types.uniq
          end
        end

        def to_graphql
          type_defn = GraphQL::InterfaceType.new
          type_defn.name = graphql_name
          type_defn.description = description
          type_defn.orphan_types = orphan_types
          fields.each do |field_name, field_inst|
            field_defn = field_inst.graphql_definition
            type_defn.fields[field_defn.name] = field_defn
          end
          if respond_to?(:resolve_type)
            type_defn.resolve_type = method(:resolve_type)
          end
          type_defn
        end
      end
    end
  end
end
