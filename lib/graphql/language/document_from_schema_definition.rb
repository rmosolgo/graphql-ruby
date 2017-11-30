# frozen_string_literal: true
module GraphQL
  module Language
    # @api private
    #
    # {GraphQL::Language::DocumentFromSchemaDefinition} is used to convert a {GraphQL::Schema} object
    # To a {GraphQL::Language::Document} AST node.
    #
    class DocumentFromSchemaDefinition
      def initialize(schema)
        @schema = schema
        @types = GraphQL::Schema::Traversal.new(schema, introspection: true).type_map.values
      end

      def document
        GraphQL::Language::Nodes::Document.new(
          definitions: build_definition_nodes
        )
      end

      protected

      def build_schema_node(schema)
        schema_node = GraphQL::Language::Nodes::SchemaDefinition.new(
          query: schema.query.name
        )

        if schema.mutation
          schema_node.mutation = schema.mutation.name
        end

        if schema.subscription
          schema_node.subscription = schema.subscription.name
        end

        schema_node
      end

      def build_object_type_node(object_type)
        GraphQL::Language::Nodes::ObjectTypeDefinition.new(
          name: object_type.name,
          interfaces: object_type.interfaces.map { |iface| build_type_name_node(iface) },
          fields: build_field_nodes(object_type.fields.values),
          description: object_type.description,
        )
      end

      def build_field_node(field)
        GraphQL::Language::Nodes::FieldDefinition.new(
          name: field.name,
          arguments: build_argument_nodes(field.arguments.values),
          type: build_type_name_node(field.type),
          description: field.description,
        )
      end

      def build_union_type_node(union_type)
        GraphQL::Language::Nodes::UnionTypeDefinition.new(
          name: union_type.name,
          description: union_type.description,
          types: union_type.possible_types.map { |type| build_type_name_node(type) }
        )
      end

      def build_interface_type_node(interface_type)
        GraphQL::Language::Nodes::InterfaceTypeDefinition.new(
          name: interface_type.name,
          description: interface_type.description,
          fields: build_field_nodes(interface_type.fields.values)
        )
      end

      def build_enum_type_node(enum_type)
        GraphQL::Language::Nodes::EnumTypeDefinition.new(
          name: enum_type.name,
          values: enum_type.values.values.map do |enum_value|
            build_enum_value_node(enum_value)
          end,
          description: enum_type.description,
        )
      end

      def build_enum_value_node(enum_value)
        GraphQL::Language::Nodes::EnumValueDefinition.new(
          name: enum_value.name,
          description: enum_value.description,
        )
      end

      def build_scalar_type_node(scalar_type)
        GraphQL::Language::Nodes::ScalarTypeDefinition.new(
          name: scalar_type.name,
          description: scalar_type.description,
        )
      end

      def build_argument_node(argument)
        GraphQL::Language::Nodes::InputValueDefinition.new(
          name: argument.name,
          description: argument.description,
          type: build_type_name_node(argument.type),
          default_value: argument.default_value,
        )
      end

      def build_input_object_node(input_object)
        GraphQL::Language::Nodes::InputObjectTypeDefinition.new(
          name: input_object.name,
          fields: build_argument_nodes(input_object.arguments.values),
          description: input_object.description,
        )
      end

      def build_directive_node(directive)
        GraphQL::Language::Nodes::DirectiveDefinition.new(
          name: directive.name,
          arguments: build_argument_nodes(directive.arguments.values),
          locations: directive.locations.map(&:to_s),
          description: directive.description,
        )
      end

      def build_type_name_node(type)
        case type
        when GraphQL::ListType
          GraphQL::Language::Nodes::ListType.new(
            of_type: build_type_name_node(type.of_type)
          )
        when GraphQL::NonNullType
          GraphQL::Language::Nodes::NonNullType.new(
            of_type: build_type_name_node(type.of_type)
          )
        else
          GraphQL::Language::Nodes::TypeName.new(name: type.name)
        end
      end

      def build_type_definition_node(type)
        case type
        when GraphQL::ObjectType
          build_object_type_node(type)
        when GraphQL::UnionType
          build_union_type_node(type)
        when GraphQL::InterfaceType
          build_interface_type_node(type)
        when GraphQL::ScalarType
          build_scalar_type_node(type)
        when GraphQL::EnumType
          build_enum_type_node(type)
        when GraphQL::InputObjectType
          build_input_object_node(type)
        else
          raise TypeError
        end
      end

      def build_argument_nodes(arguments)
        arguments.map { |arg| build_argument_node(arg) }
      end

      def build_directive_nodes(directives)
        directives.map { |directive| build_directive_node(directive) }
      end

      def build_definition_nodes
        definitions = build_type_definition_nodes(types)
        definitions += build_directive_nodes(schema.directives.values)
        definitions << build_schema_node(schema)
        definitions
      end

      def build_type_definition_nodes(types)
        types.map { |type| build_type_definition_node(type) }
      end

      def build_field_nodes(fields)
        fields.map { |field| build_field_node(field) }
      end

      private

      attr_reader :schema, :types
    end
  end
end
