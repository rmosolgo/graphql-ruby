# frozen_string_literal: true
module GraphQL
  module Language
    # @api private
    #
    # {GraphQL::Language::DocumentFromSchemaDefinition} is used to convert a {GraphQL::Schema} object
    # To a {GraphQL::Language::Document} AST node.
    #
    # @param context [GraphQL::Query::Context] the optional query context
    # @param warden [GraphQL::Schema::Warden] An optional schema warden to hide certain nodes
    # @param include_introspection_types [Boolean] Wether or not to print introspection types
    # @param include_introspection_types [Boolean] Wether or not to print built in types and directives
    class DocumentFromSchemaDefinition
      def initialize(
        schema, context: nil, only: nil, except: nil, include_introspection_types: false,
        include_built_ins: false, always_include_schema: false
      )
        @schema = schema
        @always_include_schema = always_include_schema

        filter = GraphQL::Language::DocumentFromSchemaDefinition::Filter.new(
          only,
          except,
          include_introspection_types: include_introspection_types,
          include_built_ins: include_built_ins,
        )

        @warden = GraphQL::Schema::Warden.new(
          filter,
          schema: @schema,
          context: @context
        )
      end

      def document
        GraphQL::Language::Nodes::Document.new(
          definitions: build_definition_nodes
        )
      end

      def build_schema_node
        schema_node = GraphQL::Language::Nodes::SchemaDefinition.new

        if schema.query && warden.get_type(schema.query.name)
          schema_node.query = schema.query.name
        end

        if schema.mutation && warden.get_type(schema.mutation.name)
          schema_node.mutation = schema.mutation.name
        end

        if schema.subscription && warden.get_type(schema.subscription.name)
          schema_node.subscription = schema.subscription.name
        end

        schema_node
      end

      def build_object_type_node(object_type)
        GraphQL::Language::Nodes::ObjectTypeDefinition.new(
          name: object_type.name,
          interfaces: warden.interfaces(object_type).map { |iface| build_type_name_node(iface) },
          fields: build_field_nodes(warden.fields(object_type)),
          description: object_type.description,
        )
      end

      def build_field_node(field)
        GraphQL::Language::Nodes::FieldDefinition.new(
          name: field.name,
          arguments: build_argument_nodes(warden.arguments(field)),
          type: build_type_name_node(field.type),
          description: field.description,
        )
      end

      def build_union_type_node(union_type)
        GraphQL::Language::Nodes::UnionTypeDefinition.new(
          name: union_type.name,
          description: union_type.description,
          types: warden.possible_types(union_type).map { |type| build_type_name_node(type) }
        )
      end

      def build_interface_type_node(interface_type)
        GraphQL::Language::Nodes::InterfaceTypeDefinition.new(
          name: interface_type.name,
          description: interface_type.description,
          fields: build_field_nodes(warden.fields(interface_type))
        )
      end

      def build_enum_type_node(enum_type)
        GraphQL::Language::Nodes::EnumTypeDefinition.new(
          name: enum_type.name,
          values: warden.enum_values(enum_type).map do |enum_value|
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
          fields: build_argument_nodes(warden.arguments(input_object)),
          description: input_object.description,
        )
      end

      def build_directive_node(directive)
        GraphQL::Language::Nodes::DirectiveDefinition.new(
          name: directive.name,
          arguments: build_argument_nodes(warden.arguments(directive)),
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
        definitions = build_type_definition_nodes(warden.types)
        definitions += build_directive_nodes(warden.directives)
        definitions << build_schema_node if include_schema_node?
        definitions
      end

      def build_type_definition_nodes(types)
        types.map { |type| build_type_definition_node(type) }
      end

      def build_field_nodes(fields)
        fields.map { |field| build_field_node(field) }
      end

      class Filter
        def initialize(only, except, include_introspection_types:, include_built_ins:)
          @only = only
          @except = except
          @include_introspection_types = include_introspection_types
          @include_built_ins = include_built_ins
        end

        def call(member, context)
          if !include_introspection_types && introspection?(member)
            return false
          end

          if !include_built_ins && built_in?(member)
            return false
          end

          if only
            !only.call(member, context)
          elsif except
            except.call(member, context)
          else
            true
          end
        end

        private

        attr_reader :include_introspection_types, :include_built_ins,
          :only, :except

        def introspection?(member)
          member.is_a?(BaseType) && member.introspection?
        end

        def built_in?(member)
          (member.is_a?(GraphQL::ScalarType) && member.default_scalar?) ||
          (member.is_a?(GraphQL::Directive) && member.default_directive?)
        end
      end

      private

      def include_schema_node?
        @always_include_schema || !schema.respects_root_name_conventions?
      end

      attr_reader :schema, :warden
    end
  end
end
