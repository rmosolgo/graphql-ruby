# frozen_string_literal: true
require "graphql/schema/build_from_definition/resolve_map"

module GraphQL
  class Schema
    module BuildFromDefinition
      class << self
        def from_definition(definition_string, default_resolve:, parser: DefaultParser)
          document = parser.parse(definition_string)
          Builder.build(document, default_resolve: default_resolve)
        end
      end

      # @api private
      DefaultParser = GraphQL::Language::Parser

      # @api private
      module DefaultResolve
        def self.call(type, field, obj, args, ctx)
          if field.arguments.any?
            obj.public_send(field.name, args, ctx)
          else
            obj.public_send(field.name)
          end
        end
      end

      # @api private
      module Builder
        extend self

        def build(document, default_resolve: DefaultResolve)
          raise InvalidDocumentError.new('Must provide a document ast.') if !document || !document.is_a?(GraphQL::Language::Nodes::Document)

          if default_resolve.is_a?(Hash)
            default_resolve = ResolveMap.new(default_resolve)
          end

          schema_definition = nil
          types = {}
          types.merge!(GraphQL::Schema::BUILT_IN_TYPES)
          directives = {}
          type_resolver = ->(type) { -> { resolve_type(types, type) } }

          document.definitions.each do |definition|
            case definition
            when GraphQL::Language::Nodes::SchemaDefinition
              raise InvalidDocumentError.new('Must provide only one schema definition.') if schema_definition
              schema_definition = definition
            when GraphQL::Language::Nodes::EnumTypeDefinition
              types[definition.name] = build_enum_type(definition, type_resolver)
            when GraphQL::Language::Nodes::ObjectTypeDefinition
              types[definition.name] = build_object_type(definition, type_resolver, default_resolve: default_resolve)
            when GraphQL::Language::Nodes::InterfaceTypeDefinition
              types[definition.name] = build_interface_type(definition, type_resolver)
            when GraphQL::Language::Nodes::UnionTypeDefinition
              types[definition.name] = build_union_type(definition, type_resolver)
            when GraphQL::Language::Nodes::ScalarTypeDefinition
              types[definition.name] = build_scalar_type(definition, type_resolver, default_resolve: default_resolve)
            when GraphQL::Language::Nodes::InputObjectTypeDefinition
              types[definition.name] = build_input_object_type(definition, type_resolver)
            when GraphQL::Language::Nodes::DirectiveDefinition
              directives[definition.name] = build_directive(definition, type_resolver)
            end
          end

          directives = GraphQL::Schema.default_directives.merge(directives)

          if schema_definition
            if schema_definition.query
              raise InvalidDocumentError.new("Specified query type \"#{schema_definition.query}\" not found in document.") unless types[schema_definition.query]
              query_root_type = types[schema_definition.query]
            end

            if schema_definition.mutation
              raise InvalidDocumentError.new("Specified mutation type \"#{schema_definition.mutation}\" not found in document.") unless types[schema_definition.mutation]
              mutation_root_type = types[schema_definition.mutation]
            end

            if schema_definition.subscription
              raise InvalidDocumentError.new("Specified subscription type \"#{schema_definition.subscription}\" not found in document.") unless types[schema_definition.subscription]
              subscription_root_type = types[schema_definition.subscription]
            end
          else
            query_root_type = types['Query']
            mutation_root_type = types['Mutation']
            subscription_root_type = types['Subscription']
          end

          raise InvalidDocumentError.new('Must provide schema definition with query type or a type named Query.') unless query_root_type

          schema = Schema.define do
            raise_definition_error true

            query query_root_type
            mutation mutation_root_type
            subscription subscription_root_type
            orphan_types types.values
            if default_resolve.respond_to?(:resolve_type)
              resolve_type(default_resolve.method(:resolve_type))
            else
              resolve_type(NullResolveType)
            end

            directives directives.values
          end

          schema.ast_node = schema_definition if schema_definition

          schema
        end

        NullResolveType = ->(type, obj, ctx) {
          raise(GraphQL::RequiredImplementationMissingError, "Generated Schema cannot use Interface or Union types for execution. Implement resolve_type on your resolver.")
        }

        NullScalarCoerce = ->(val, _ctx) { val }

        def build_enum_type(enum_type_definition, type_resolver)
          enum = GraphQL::EnumType.define(
            name: enum_type_definition.name,
            description: enum_type_definition.description,
            values: enum_type_definition.values.map do |enum_value_definition|
              value = EnumType::EnumValue.define(
                name: enum_value_definition.name,
                value: enum_value_definition.name,
                deprecation_reason: build_deprecation_reason(enum_value_definition.directives),
                description: enum_value_definition.description,
              )

              value.ast_node = enum_value_definition

              value
            end
          )

          enum.ast_node = enum_type_definition

          enum
        end

        def build_deprecation_reason(directives)
          deprecated_directive = directives.find{ |d| d.name == 'deprecated' }
          return unless deprecated_directive

          reason = deprecated_directive.arguments.find{ |a| a.name == 'reason' }
          return GraphQL::Directive::DEFAULT_DEPRECATION_REASON unless reason

          reason.value
        end

        def build_scalar_type(scalar_type_definition, type_resolver, default_resolve:)
          scalar_type = GraphQL::ScalarType.define(
            name: scalar_type_definition.name,
            description: scalar_type_definition.description,
            coerce: NullScalarCoerce,
          )

          scalar_type.ast_node = scalar_type_definition

          if default_resolve.respond_to?(:coerce_input)
            scalar_type = scalar_type.redefine(
              coerce_input: ->(val, ctx) { default_resolve.coerce_input(scalar_type, val, ctx) },
              coerce_result: ->(val, ctx) { default_resolve.coerce_result(scalar_type, val, ctx) },
            )
          end

          scalar_type
        end

        def build_union_type(union_type_definition, type_resolver)
          union = GraphQL::UnionType.define(
            name: union_type_definition.name,
            description: union_type_definition.description,
            possible_types: union_type_definition.types.map{ |type_name| type_resolver.call(type_name) },
          )

          union.ast_node = union_type_definition

          union
        end

        def build_object_type(object_type_definition, type_resolver, default_resolve:)
          type_def = nil
          typed_resolve_fn = ->(field, obj, args, ctx) { default_resolve.call(type_def, field, obj, args, ctx) }
          type_def = GraphQL::ObjectType.define(
            name: object_type_definition.name,
            description: object_type_definition.description,
            fields: Hash[build_fields(object_type_definition.fields, type_resolver, default_resolve: typed_resolve_fn)],
            interfaces: object_type_definition.interfaces.map{ |interface_name| type_resolver.call(interface_name) },
          )
          type_def.ast_node = object_type_definition
          type_def
        end

        def build_input_object_type(input_object_type_definition, type_resolver)
          input = GraphQL::InputObjectType.define(
            name: input_object_type_definition.name,
            description: input_object_type_definition.description,
            arguments: Hash[build_input_arguments(input_object_type_definition, type_resolver)],
          )

          input.ast_node = input_object_type_definition

          input
        end

        def build_default_value(default_value)
          case default_value
          when GraphQL::Language::Nodes::Enum
            default_value.name
          when GraphQL::Language::Nodes::NullValue
            nil
          when GraphQL::Language::Nodes::InputObject
            default_value.to_h
          when Array
            default_value.map { |v| build_default_value(v) }
          else
            default_value
          end
        end

        def build_input_arguments(input_object_type_definition, type_resolver)
          input_object_type_definition.fields.map do |input_argument|
            kwargs = {}

            if !input_argument.default_value.nil?
              kwargs[:default_value] = build_default_value(input_argument.default_value)
            end

            argument = GraphQL::Argument.define(
              name: input_argument.name,
              type: type_resolver.call(input_argument.type),
              description: input_argument.description,
              method_access: false,
              **kwargs,
            )

            argument.ast_node = input_argument

            [
              input_argument.name,
              argument
            ]
          end
        end

        def build_directive(directive_definition, type_resolver)
          directive = GraphQL::Directive.define(
            name: directive_definition.name,
            description: directive_definition.description,
            arguments: Hash[build_directive_arguments(directive_definition, type_resolver)],
            locations: directive_definition.locations.map { |location| location.name.to_sym },
          )

          directive.ast_node = directive_definition

          directive
        end

        def build_directive_arguments(directive_definition, type_resolver)
          directive_definition.arguments.map do |directive_argument|
            kwargs = {}

            if !directive_argument.default_value.nil?
              kwargs[:default_value] = build_default_value(directive_argument.default_value)
            end

            argument = GraphQL::Argument.define(
              name: directive_argument.name,
              type: type_resolver.call(directive_argument.type),
              description: directive_argument.description,
              method_access: false,
              **kwargs,
            )

            argument.ast_node = directive_argument

            [
              directive_argument.name,
              argument
            ]
          end
        end

        def build_interface_type(interface_type_definition, type_resolver)
          interface = GraphQL::InterfaceType.define(
            name: interface_type_definition.name,
            description: interface_type_definition.description,
            fields: Hash[build_fields(interface_type_definition.fields, type_resolver, default_resolve: nil)],
          )

          interface.ast_node = interface_type_definition

          interface
        end

        def build_fields(field_definitions, type_resolver, default_resolve:)
          field_definitions.map do |field_definition|
            field_arguments = Hash[field_definition.arguments.map do |argument|
              kwargs = {}

              if !argument.default_value.nil?
                kwargs[:default_value] = build_default_value(argument.default_value)
              end

              arg = GraphQL::Argument.define(
                name: argument.name,
                description: argument.description,
                type: type_resolver.call(argument.type),
                method_access: false,
                **kwargs,
              )

              arg.ast_node = argument

              [argument.name, arg]
            end]

            field = GraphQL::Field.define(
              name: field_definition.name,
              description: field_definition.description,
              type: type_resolver.call(field_definition.type),
              arguments: field_arguments,
              resolve: ->(obj, args, ctx) { default_resolve.call(field, obj, args, ctx) },
              deprecation_reason: build_deprecation_reason(field_definition.directives),
            )

            field.ast_node = field_definition

            type_name = resolve_type_name(field_definition.type)
            field.connection = type_name.end_with?("Connection")
            [field_definition.name, field]
          end
        end

        def resolve_type(types, ast_node)
          type = GraphQL::Schema::TypeExpression.build_type(types, ast_node)
          if type.nil?
            while ast_node.respond_to?(:of_type)
              ast_node = ast_node.of_type
            end
            raise InvalidDocumentError.new("Type \"#{ast_node.name}\" not found in document.")
          end
          type
        end

        def resolve_type_name(type)
          case type
          when GraphQL::Language::Nodes::TypeName
            return type.name
          else
            resolve_type_name(type.of_type)
          end
        end
      end

      private_constant :Builder
    end
  end
end
