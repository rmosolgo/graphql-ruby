module GraphQL
  class Schema
    module BuildFromDefinition
      class Builder
        def initialize(definition_string)
          document = GraphQL::parse(definition_string)

          if !document || !document.is_a?(GraphQL::Language::Nodes::Document)
            raise InvalidDocumentError.new('Must provide a document ast.')
          end

          @document = document
          @type_resolver = -> (type) { -> { resolve_type(types, type) } }

          @types = {}
          @types.merge!(GraphQL::Schema::BUILT_IN_TYPES)
        end

        def build
          schema_definition = nil
          directives = {}

          document.definitions.each do |definition|
            case definition
            when GraphQL::Language::Nodes::SchemaDefinition
              raise InvalidDocumentError.new('Must provide only one schema definition.') if schema_definition
              schema_definition = definition
            when GraphQL::Language::Nodes::EnumTypeDefinition
              types[definition.name] = build_enum_type(definition)
            when GraphQL::Language::Nodes::ObjectTypeDefinition
              types[definition.name] = build_object_type(definition)
            when GraphQL::Language::Nodes::InterfaceTypeDefinition
              types[definition.name] = build_interface_type(definition)
            when GraphQL::Language::Nodes::UnionTypeDefinition
              types[definition.name] = build_union_type(definition)
            when GraphQL::Language::Nodes::ScalarTypeDefinition
              types[definition.name] = build_scalar_type(definition)
            when GraphQL::Language::Nodes::InputObjectTypeDefinition
              types[definition.name] = build_input_object_type(definition)
            when GraphQL::Language::Nodes::DirectiveDefinition
              directives[definition.name] = build_directive(definition)
            end
          end

          GraphQL::Schema::DIRECTIVES.each do |built_in_directive|
            directives[built_in_directive.name] = built_in_directive unless directives[built_in_directive.name]
          end

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

          orphans = @types

          Schema.define do
            query query_root_type
            mutation mutation_root_type
            subscription subscription_root_type
            orphan_types orphans.values
            resolve_type NullResolveType

            directives directives.values
          end
        end

        NullResolveType = -> (obj, ctx) {
          raise(NotImplementedError, "Generated Schema cannot use Interface or Union types for execution.")
        }

        protected

        def build_enum_type(enum_type_definition)
          GraphQL::EnumType.define(
            name: enum_type_definition.name,
            description: enum_type_definition.description,
            values: enum_type_definition.values.map do |enum_value_definition|
              EnumType::EnumValue.define(
                name: enum_value_definition.name,
                value: enum_value_definition.name,
                deprecation_reason: build_deprecation_reason(enum_value_definition.directives),
                description: enum_value_definition.description,
              )
            end
          )
        end

        def build_deprecation_reason(directives)
          deprecated_directive = directives.find{ |d| d.name == 'deprecated' }
          return unless deprecated_directive

          reason = deprecated_directive.arguments.find{ |a| a.name == 'reason' }
          return GraphQL::Directive::DEFAULT_DEPRECATION_REASON unless reason

          reason.value
        end

        def build_scalar_type(scalar_type_definition)
          GraphQL::ScalarType.define(
            name: scalar_type_definition.name,
            description: scalar_type_definition.description,
          )
        end

        def build_union_type(union_type_definition)
          GraphQL::UnionType.define(
            name: union_type_definition.name,
            description: union_type_definition.description,
            possible_types: union_type_definition.types.map{ |type_name| type_resolver.call(type_name) },
          )
        end

        def build_object_type(object_type_definition)
          GraphQL::ObjectType.define(
            name: object_type_definition.name,
            description: object_type_definition.description,
            fields: Hash[build_fields(object_type_definition.fields)],
            interfaces: object_type_definition.interfaces.map{ |interface_name| type_resolver.call(interface_name) },
          )
        end

        def build_input_object_type(input_object_type_definition)
          GraphQL::InputObjectType.define(
            name: input_object_type_definition.name,
            description: input_object_type_definition.description,
            arguments: Hash[build_input_arguments(input_object_type_definition)],
          )
        end

        def build_input_arguments(input_object_type_definition)
          input_object_type_definition.fields.map do |input_argument|
            default_value = case input_argument.default_value
            when GraphQL::Language::Nodes::Enum
              input_argument.default_value.name
            else
              input_argument.default_value
            end

            [
              input_argument.name,
              GraphQL::Argument.define(
                name: input_argument.name,
                type: type_resolver.call(input_argument.type),
                description: input_argument.description,
                default_value: default_value,
              )
            ]
          end
        end

        def build_directive(directive_definition)
          GraphQL::Directive.define(
            name: directive_definition.name,
            description: directive_definition.description,
            arguments: Hash[build_directive_arguments(directive_definition)],
            locations: directive_definition.locations.map(&:to_sym),
          )
        end

        def build_directive_arguments(directive_definition)
          directive_definition.arguments.map do |directive_argument|
            [
              directive_argument.name,
              GraphQL::Argument.define(
                name: directive_argument.name,
                type: type_resolver.call(directive_argument.type),
                description: directive_argument.description,
                default_value: directive_argument.default_value,
              )
            ]
          end
        end

        def build_interface_type(interface_type_definition)
          GraphQL::InterfaceType.define(
            name: interface_type_definition.name,
            description: interface_type_definition.description,
            fields: Hash[build_fields(interface_type_definition.fields)],
          )
        end

        def build_fields(field_definitions)
          field_definitions.map do |field_definition|
            field_arguments =  Hash[build_field_arguments(field_definition.arguments)]
            [field_definition.name, build_field(field_definition, field_arguments)]
          end
        end

        def build_field(field_definition, arguments)
          GraphQL::Field.define(
            name: field_definition.name,
            description: field_definition.description,
            type: type_resolver.call(field_definition.type),
            arguments: arguments,
            deprecation_reason: build_deprecation_reason(field_definition.directives),
          )
        end

        def build_field_arguments(arguments)
          arguments.map do |argument|
            [argument.name, build_field_argument(argument)]
          end
        end

        def build_field_argument(argument)
          default_value = case argument.default_value
          when GraphQL::Language::Nodes::Enum
            argument.default_value.name
          else
            argument.default_value
          end

          GraphQL::Argument.define(
            name: argument.name,
            description: argument.description,
            type: type_resolver.call(argument.type),
            default_value: default_value,
          )
        end

        def resolve_type(types, ast_node)
          type = GraphQL::Schema::TypeExpression.build_type(types, ast_node)
          raise InvalidDocumentError.new("Type \"#{ast_node.name}\" not found in document.") unless type
          type
        end

        private

        attr_reader :document, :type_resolver, :types
      end
    end
  end
end
