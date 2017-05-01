# frozen_string_literal: true
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
      class ResolveMap
        
        def initialize(resolve_hash)
          @resolve_hash = convert_keys_to_strings(resolve_hash)
        end

        def call(type, field, obj, args, ctx)
          type_hash = @resolve_hash[type.name]

          if !type_hash
            type_hash = @resolve_hash[type.name] = {}
          end

          resolver = type_hash[field.name]

          if resolver.nil?
            raise(KeyError, "resolver not found for #{type.name}.#{field.name}") unless obj.respond_to?(field.name)
            resolver = type_hash[field.name] = build_resolver(type, field, obj)
          end

          resolver.call(obj, args, ctx)
        end

        def after_build_schema(schema) 
          hookup_union(schema)
          hookup_scalars(schema)
        end

        private

        def build_resolver(type, field, obj)
          method_arity = obj.method(field.name.to_sym).arity
          case method_arity
          # Some objects have dynamic missing method such as openstruct
          # therefore they have an arity -1
          when -1, 0
            ->(o, a, c) { o.public_send(field.name) }
          when 1
            ->(o, a, c) { o.public_send(field.name, a) }
          when 2
            ->(o, a, c) { o.public_send(field.name, a, c) }
          else 
            raise "Unexpected resolve arity: #{method_arity}. Must be 0, 1, 2"
          end
        end
       
        def hookup_union(schema)
          schema.resolve_type = @resolve_hash["__resolve_type"] if @resolve_hash["__resolve_type"]
        end

        def hookup_scalars(schema)
          for _, type in schema.types
            next unless type.is_a?(GraphQL::ScalarType) and @resolve_hash[type.name]
          
            type.coerce        = @resolve_hash[type.name]["coerce"]        if @resolve_hash[type.name]["coerce"]
            type.coerce_input  = @resolve_hash[type.name]["coerce_input"]  if @resolve_hash[type.name]["coerce_input"]
            type.coerce_result = @resolve_hash[type.name]["coerce_result"] if @resolve_hash[type.name]["coerce_result"]
          end
        end
       
        def convert_keys_to_strings(h)
          Hash[
            h.map {|k, v|
              v = convert_keys_to_strings(v) if v.is_a?(Hash)
              [k.to_s, v]
            }
          ]
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
              types[definition.name] = build_scalar_type(definition, type_resolver)
            when GraphQL::Language::Nodes::InputObjectTypeDefinition
              types[definition.name] = build_input_object_type(definition, type_resolver)
            when GraphQL::Language::Nodes::DirectiveDefinition
              directives[definition.name] = build_directive(definition, type_resolver)
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

          schema = Schema.define do
            raise_definition_error true

            query query_root_type
            mutation mutation_root_type
            subscription subscription_root_type
            orphan_types types.values
            resolve_type NullResolveType

            directives directives.values
          end

          if default_resolve.respond_to? :after_build_schema
            default_resolve.after_build_schema(schema)
          end

          schema
        end

        NullResolveType = ->(obj, ctx) {
          raise(NotImplementedError, "Generated Schema cannot use Interface or Union types for execution.")
        }

        NullScalarCoerce = ->(val, _ctx) { val }

        def build_enum_type(enum_type_definition, type_resolver)
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

        def build_scalar_type(scalar_type_definition, type_resolver)
          GraphQL::ScalarType.define(
            name: scalar_type_definition.name,
            description: scalar_type_definition.description,
            coerce: NullScalarCoerce,
          )
        end

        def build_union_type(union_type_definition, type_resolver)
          GraphQL::UnionType.define(
            name: union_type_definition.name,
            description: union_type_definition.description,
            possible_types: union_type_definition.types.map{ |type_name| type_resolver.call(type_name) },
          )
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
        end

        def build_input_object_type(input_object_type_definition, type_resolver)
          GraphQL::InputObjectType.define(
            name: input_object_type_definition.name,
            description: input_object_type_definition.description,
            arguments: Hash[build_input_arguments(input_object_type_definition, type_resolver)],
          )
        end

        def build_default_value(default_value)
          case default_value
          when GraphQL::Language::Nodes::Enum
            default_value.name
          when GraphQL::Language::Nodes::NullValue
            nil
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

            [
              input_argument.name,
              GraphQL::Argument.define(
                name: input_argument.name,
                type: type_resolver.call(input_argument.type),
                description: input_argument.description,
                **kwargs,
              )
            ]
          end
        end

        def build_directive(directive_definition, type_resolver)
          GraphQL::Directive.define(
            name: directive_definition.name,
            description: directive_definition.description,
            arguments: Hash[build_directive_arguments(directive_definition, type_resolver)],
            locations: directive_definition.locations.map(&:to_sym),
          )
        end

        def build_directive_arguments(directive_definition, type_resolver)
          directive_definition.arguments.map do |directive_argument|
            kwargs = {}

            if !directive_argument.default_value.nil?
              kwargs[:default_value] = build_default_value(directive_argument.default_value)
            end

            [
              directive_argument.name,
              GraphQL::Argument.define(
                name: directive_argument.name,
                type: type_resolver.call(directive_argument.type),
                description: directive_argument.description,
                **kwargs,
              )
            ]
          end
        end

        def build_interface_type(interface_type_definition, type_resolver)
          GraphQL::InterfaceType.define(
            name: interface_type_definition.name,
            description: interface_type_definition.description,
            fields: Hash[build_fields(interface_type_definition.fields, type_resolver, default_resolve: nil)],
          )
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
                **kwargs,
              )

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
            [field_definition.name, field]
          end
        end

        def resolve_type(types, ast_node)
          type = GraphQL::Schema::TypeExpression.build_type(types, ast_node)
          raise InvalidDocumentError.new("Type \"#{ast_node.name}\" not found in document.") unless type
          type
        end
      end

      private_constant :Builder
    end
  end
end
