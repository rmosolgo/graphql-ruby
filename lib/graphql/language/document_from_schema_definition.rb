# frozen_string_literal: true
module GraphQL
  module Language
    # @api private
    #
    # {GraphQL::Language::DocumentFromSchemaDefinition} is used to convert a {GraphQL::Schema} object
    # To a {GraphQL::Language::Document} AST node.
    #
    # @param context [Hash]
    # @param only [<#call(member, ctx)>]
    # @param except [<#call(member, ctx)>]
    # @param include_introspection_types [Boolean] Whether or not to include introspection types in the AST
    # @param include_built_in_scalars [Boolean] Whether or not to include built in scalars in the AST
    # @param include_built_in_directives [Boolean] Whether or not to include built in directives in the AST
    class DocumentFromSchemaDefinition
      def initialize(
        schema, context: nil, only: nil, except: nil, include_introspection_types: false,
        include_built_in_directives: false, include_built_in_scalars: false, always_include_schema: false
      )
        @schema = schema
        @always_include_schema = always_include_schema
        @include_introspection_types = include_introspection_types
        @include_built_in_scalars = include_built_in_scalars
        @include_built_in_directives = include_built_in_directives

        filter = GraphQL::Filter.new(only: only, except: except)
        if @schema.respond_to?(:visible?)
          filter = filter.merge(only: @schema.method(:visible?))
        end

        schema_context = schema.context_class.new(query: nil, object: nil, schema: schema, values: context)
        @warden = GraphQL::Schema::Warden.new(
          filter,
          schema: @schema,
          context: schema_context,
        )
      end

      def document
        GraphQL::Language::Nodes::Document.new(
          definitions: build_definition_nodes
        )
      end

      def build_schema_node
        GraphQL::Language::Nodes::SchemaDefinition.new(
          query: (q = warden.root_type_for_operation("query")) && q.graphql_name,
          mutation: (m = warden.root_type_for_operation("mutation")) && m.graphql_name,
          subscription: (s = warden.root_type_for_operation("subscription")) && s.graphql_name,
          # This only supports directives from parsing,
          # use a custom printer to add to this list.
          #
          # `@schema.directives` is covered by `build_definition_nodes`
          directives: ast_directives(@schema),
        )
      end

      def build_object_type_node(object_type)
        GraphQL::Language::Nodes::ObjectTypeDefinition.new(
          name: object_type.graphql_name,
          interfaces: warden.interfaces(object_type).sort_by(&:graphql_name).map { |iface| build_type_name_node(iface) },
          fields: build_field_nodes(warden.fields(object_type)),
          description: object_type.description,
          directives: directives(object_type),
        )
      end

      def build_field_node(field)
        GraphQL::Language::Nodes::FieldDefinition.new(
          name: field.graphql_name,
          arguments: build_argument_nodes(warden.arguments(field)),
          type: build_type_name_node(field.type),
          description: field.description,
          directives: directives(field),
        )
      end

      def build_union_type_node(union_type)
        GraphQL::Language::Nodes::UnionTypeDefinition.new(
          name: union_type.graphql_name,
          description: union_type.description,
          types: warden.possible_types(union_type).sort_by(&:graphql_name).map { |type| build_type_name_node(type) },
          directives: directives(union_type),
        )
      end

      def build_interface_type_node(interface_type)
        GraphQL::Language::Nodes::InterfaceTypeDefinition.new(
          name: interface_type.graphql_name,
          description: interface_type.description,
          fields: build_field_nodes(warden.fields(interface_type)),
          directives: directives(interface_type),
        )
      end

      def build_enum_type_node(enum_type)
        GraphQL::Language::Nodes::EnumTypeDefinition.new(
          name: enum_type.graphql_name,
          values: warden.enum_values(enum_type).sort_by(&:graphql_name).map do |enum_value|
            build_enum_value_node(enum_value)
          end,
          description: enum_type.description,
          directives: directives(enum_type),
        )
      end

      def build_enum_value_node(enum_value)
        GraphQL::Language::Nodes::EnumValueDefinition.new(
          name: enum_value.graphql_name,
          description: enum_value.description,
          directives: directives(enum_value),
        )
      end

      def build_scalar_type_node(scalar_type)
        GraphQL::Language::Nodes::ScalarTypeDefinition.new(
          name: scalar_type.graphql_name,
          description: scalar_type.description,
          directives: directives(scalar_type),
        )
      end

      def build_argument_node(argument)
        if argument.default_value?
          default_value = build_default_value(argument.default_value, argument.type)
        else
          default_value = nil
        end

        argument_node = GraphQL::Language::Nodes::InputValueDefinition.new(
          name: argument.graphql_name,
          description: argument.description,
          type: build_type_name_node(argument.type),
          default_value: default_value,
          directives: directives(argument),
        )

        argument_node
      end

      def build_input_object_node(input_object)
        GraphQL::Language::Nodes::InputObjectTypeDefinition.new(
          name: input_object.graphql_name,
          fields: build_argument_nodes(warden.arguments(input_object)),
          description: input_object.description,
          directives: directives(input_object),
        )
      end

      def build_directive_node(directive)
        GraphQL::Language::Nodes::DirectiveDefinition.new(
          name: directive.graphql_name,
          arguments: build_argument_nodes(warden.arguments(directive)),
          locations: build_directive_location_nodes(directive.locations),
          description: directive.description,
        )
      end

      def build_directive_location_nodes(locations)
        locations.sort.map { |location| build_directive_location_node(location) }
      end

      def build_directive_location_node(location)
        GraphQL::Language::Nodes::DirectiveLocation.new(
          name: location.to_s
        )
      end

      def build_type_name_node(type)
        case type.kind.name
        when "LIST"
          GraphQL::Language::Nodes::ListType.new(
            of_type: build_type_name_node(type.of_type)
          )
        when "NON_NULL"
          GraphQL::Language::Nodes::NonNullType.new(
            of_type: build_type_name_node(type.of_type)
          )
        else
          GraphQL::Language::Nodes::TypeName.new(name: type.graphql_name)
        end
      end

      def build_default_value(default_value, type)
        if default_value.nil?
          return GraphQL::Language::Nodes::NullValue.new(name: "null")
        end

        case type.kind.name
        when "SCALAR"
          type.coerce_isolated_result(default_value)
        when "ENUM"
          GraphQL::Language::Nodes::Enum.new(name: type.coerce_isolated_result(default_value))
        when "INPUT_OBJECT"
          GraphQL::Language::Nodes::InputObject.new(
            arguments: default_value.to_h.map do |arg_name, arg_value|
              arg_type = type.arguments.fetch(arg_name.to_s).type
              GraphQL::Language::Nodes::Argument.new(
                name: arg_name.to_s,
                value: build_default_value(arg_value, arg_type)
              )
            end
          )
        when "NON_NULL"
          build_default_value(default_value, type.of_type)
        when "LIST"
          default_value.to_a.map { |v| build_default_value(v, type.of_type) }
        else
          raise GraphQL::RequiredImplementationMissingError, "Unexpected default value type #{type.inspect}"
        end
      end

      def build_type_definition_node(type)
        case type.kind.name
        when "OBJECT"
          build_object_type_node(type)
        when "UNION"
          build_union_type_node(type)
        when "INTERFACE"
          build_interface_type_node(type)
        when "SCALAR"
          build_scalar_type_node(type)
        when "ENUM"
          build_enum_type_node(type)
        when "INPUT_OBJECT"
          build_input_object_node(type)
        else
          raise TypeError
        end
      end

      def build_argument_nodes(arguments)
        arguments
          .map { |arg| build_argument_node(arg) }
          .sort_by(&:name)
      end

      def build_directive_nodes(directives)
        if !include_built_in_directives
          directives = directives.reject { |directive| directive.default_directive? }
        end

        directives
          .map { |directive| build_directive_node(directive) }
          .sort_by(&:name)
      end

      def build_definition_nodes
        definitions = []
        definitions << build_schema_node if include_schema_node?
        definitions += build_directive_nodes(warden.directives)
        definitions += build_type_definition_nodes(warden.reachable_types)
        definitions
      end

      def build_type_definition_nodes(types)
        if !include_introspection_types
          types = types.reject { |type| type.introspection? }
        end

        if !include_built_in_scalars
          types = types.reject { |type| type.kind.scalar? && type.default_scalar? }
        end

        types
          .map { |type| build_type_definition_node(type) }
          .sort_by(&:name)
      end

      def build_field_nodes(fields)
        fields
          .map { |field| build_field_node(field) }
          .sort_by(&:name)
      end

      private

      def include_schema_node?
        always_include_schema || !schema_respects_root_name_conventions?(schema)
      end

      def schema_respects_root_name_conventions?(schema)
        (schema.query.nil? || schema.query.graphql_name == 'Query') &&
        (schema.mutation.nil? || schema.mutation.graphql_name == 'Mutation') &&
        (schema.subscription.nil? || schema.subscription.graphql_name == 'Subscription')
      end

      def directives(member)
        definition_directives(member)
      end

      def definition_directives(member)
        dirs = if !member.respond_to?(:directives) || member.directives.empty?
          []
        else
          member.directives.map do |dir|
            args = []
            dir.arguments.argument_values.each_value do |arg_value|
              arg_defn = arg_value.definition
              if arg_defn.default_value? && arg_value.value == arg_defn.default_value
                next
              else
                value_node = build_default_value(arg_value.value, arg_value.definition.type)
                args << GraphQL::Language::Nodes::Argument.new(
                  name: arg_value.definition.name,
                  value: value_node,
                )
              end
            end
            GraphQL::Language::Nodes::Directive.new(
              name: dir.class.graphql_name,
              arguments: args
            )
          end
        end

        # This is just for printing legacy `.define { ... }` schemas, where `deprecation_reason` isn't added to `.directives`.
        if !member.respond_to?(:directives) && member.respond_to?(:deprecation_reason) && (reason = member.deprecation_reason)
          arguments = []

          if reason != GraphQL::Schema::Directive::DEFAULT_DEPRECATION_REASON
            arguments << GraphQL::Language::Nodes::Argument.new(
              name: "reason",
              value: reason
            )
          end

          dirs << GraphQL::Language::Nodes::Directive.new(
            name: GraphQL::Directive::DeprecatedDirective.graphql_name,
            arguments: arguments
          )
        end

        dirs
      end

      def ast_directives(member)
        member.ast_node ? member.ast_node.directives : []
      end

      attr_reader :schema, :warden, :always_include_schema,
        :include_introspection_types, :include_built_in_directives, :include_built_in_scalars
    end
  end
end
