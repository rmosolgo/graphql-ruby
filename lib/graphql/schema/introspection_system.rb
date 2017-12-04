# frozen_string_literal: true
module GraphQL
  class Schema
    class IntrospectionSystem
      attr_reader :schema_type, :type_type, :schema_field, :type_by_name_field

      def initialize(schema)
        @schema = schema
        @built_in_namespace = GraphQL::Introspection
        @custom_namespace = schema.introspection_namespace || @built_in_namespace

        # Use to-graphql to avoid sharing with any previous instantiations
        @schema_type = load_constant(:SchemaType).to_graphql
        @type_type = load_constant(:TypeType).to_graphql
        @field_type = load_constant(:FieldType).to_graphql
        @directive_type = load_constant(:DirectiveType).to_graphql
        @enum_value_type = load_constant(:EnumValueType).to_graphql
        @input_value_type = load_constant(:InputValueType).to_graphql
        @type_kind_enum = load_constant(:TypeKindEnum).to_graphql
        @directive_location_enum = load_constant(:DirectiveLocationEnum).to_graphql

        # Make copies so their return types can be modified to local types
        @schema_field = GraphQL::Introspection::SchemaField.dup
        @type_by_name_field = GraphQL::Introspection::TypeByNameField.dup
      end

      def object_types
        [
          @schema_type,
          @type_type,
          @field_type,
          @directive_type,
          @enum_value_type,
          @input_value_type,
          @type_kind_enum,
          @directive_location_enum,
        ]
      end

      def entry_points
        [
          @schema_field,
          @type_by_name_field,
        ]
      end

      private

      def load_constant(class_name)
        @custom_namespace.const_get(class_name)
      rescue NameError
        # Dup the built-in so that the cached fields aren't shared
        @built_in_namespace.const_get(class_name)
      end
    end
  end
end
