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
    # @param from_ast [Boolean] If true, use the `ast_node` and `ast_extensions` which originally constructed this schema
    class DocumentFromSchemaDefinition
      def initialize(
        schema, context: nil, include_introspection_types: false,
        include_built_in_directives: false, include_built_in_scalars: false, always_include_schema: false,
        from_ast: false
      )
        @schema = schema
        @always_include_schema = always_include_schema
        @include_introspection_types = include_introspection_types
        @include_built_in_scalars = include_built_in_scalars
        @include_built_in_directives = include_built_in_directives
        @include_one_of = false
        @from_ast = from_ast

        schema_context = schema.context_class.new(query: nil, object: nil, schema: schema, values: context)


        @warden = @schema.warden_class.new(
          schema: @schema,
          context: schema_context,
        )

        schema_context.warden = @warden
      end

      def document
        GraphQL::Language::Nodes::Document.new(
          definitions: build_definition_nodes
        )
      end

      def build_schema_node
        schema_options = {
          # `@schema.directives` is covered by `build_definition_nodes`
          directives: definition_directives(@schema, :schema_directives),
        }
        if !schema_respects_root_name_conventions?(@schema)
          schema_options.merge!({
            query: (q = warden.root_type_for_operation("query")) && q.graphql_name,
            mutation: (m = warden.root_type_for_operation("mutation")) && m.graphql_name,
            subscription: (s = warden.root_type_for_operation("subscription")) && s.graphql_name,
          })
        end
        GraphQL::Language::Nodes::SchemaDefinition.new(schema_options)
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
          interfaces: warden.interfaces(interface_type).sort_by(&:graphql_name).map { |type| build_type_name_node(type) },
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
          repeatable: directive.repeatable?,
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
              args = @warden.arguments(type)
              arg = args.find { |a| a.keyword.to_s == arg_name.to_s }
              if arg.nil?
                raise ArgumentError, "No argument definition on #{type.graphql_name} for argument: #{arg_name.inspect} (expected one of: #{args.map(&:keyword)})"
              end
              GraphQL::Language::Nodes::Argument.new(
                name: arg.graphql_name.to_s,
                value: build_default_value(arg_value, arg.type)
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
        directives
          .map { |directive| build_directive_node(directive) }
          .sort_by(&:name)
      end

      def build_definition_nodes
        dirs_to_build = warden.directives
        if !include_built_in_directives
          dirs_to_build = dirs_to_build.reject { |directive| directive.default_directive? }
        end
        dir_nodes = build_directive_nodes(dirs_to_build)

        type_nodes = []
        extensions_nodes = []
        build_type_definition_nodes(warden.reachable_types, type_nodes, extensions_nodes)

        if @include_one_of
          # This may have been set to true when iterating over all types
          dir_nodes.concat(build_directive_nodes([GraphQL::Schema::Directive::OneOf]))
        end

        definitions = [*dir_nodes, *type_nodes]
        if include_schema_node?
          definitions.unshift(@from_ast ? @schema.ast_node : build_schema_node)
        end

        if @from_ast && (exts = @schema.ast_extensions)
          definitions.concat(exts)
        end
        definitions.concat(extensions_nodes)

        definitions
      end

      def build_type_definition_nodes(types, type_nodes, type_extensions_nodes)
        types.each do |type|
          if !include_introspection_types && type.introspection?
            # Nothing
          elsif !include_built_in_scalars && type.kind.scalar? && type.default_scalar?
            if @from_ast && (exts = type.ast_extensions)
              type_extensions_nodes.concat(exts)
            elsif type.directives.any?
              type_nodes << build_type_definition_node(type)
            end
          else
            if @from_ast
              type_nodes << type.ast_node
              if (exts = type.ast_extensions)
                type_extensions_nodes.concat(exts)
              end
            else
              type_nodes << build_type_definition_node(type)
            end
          end
        end

        type_nodes.sort_by!(&:name)
        type_extensions_nodes.sort_by!(&:name)

        type_nodes
      end

      def build_field_nodes(fields)
        fields
          .map { |field| build_field_node(field) }
          .sort_by(&:name)
      end

      private

      def include_schema_node?
        always_include_schema ||
          !schema_respects_root_name_conventions?(schema) ||
          !schema.schema_directives.empty?
      end

      def schema_respects_root_name_conventions?(schema)
        (schema.query.nil? || schema.query.graphql_name == 'Query') &&
        (schema.mutation.nil? || schema.mutation.graphql_name == 'Mutation') &&
        (schema.subscription.nil? || schema.subscription.graphql_name == 'Subscription')
      end

      def directives(member)
        definition_directives(member, :directives)
      end

      def definition_directives(member, directives_method)
        dirs = if !member.respond_to?(directives_method) || member.directives.empty?
          []
        else
          member.public_send(directives_method).map do |dir|
            args = []
            dir.arguments.argument_values.each_value do |arg_value| # rubocop:disable Development/ContextIsPassedCop -- directive instance method
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

            # If this schema uses this built-in directive definition,
            # include it in the print-out since it's not part of the spec yet.
            @include_one_of ||= dir.class == GraphQL::Schema::Directive::OneOf

            GraphQL::Language::Nodes::Directive.new(
              name: dir.class.graphql_name,
              arguments: args
            )
          end
        end

        dirs
      end

      attr_reader :schema, :warden, :always_include_schema,
        :include_introspection_types, :include_built_in_directives, :include_built_in_scalars
    end
  end
end
