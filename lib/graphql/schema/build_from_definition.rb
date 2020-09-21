# frozen_string_literal: true
require "graphql/schema/build_from_definition/resolve_map"

module GraphQL
  class Schema
    module BuildFromDefinition
      if !String.method_defined?(:-@)
        using GraphQL::StringDedupBackport
      end

      class << self
        # @see {Schema.from_definition}
        def from_definition(definition_string, parser: GraphQL.default_parser, **kwargs)
          from_document(parser.parse(definition_string), **kwargs)
        end

        def from_definition_path(definition_path, parser: GraphQL.default_parser, **kwargs)
          from_document(parser.parse_file(definition_path), **kwargs)
        end

        def from_document(document, default_resolve:, using: {}, relay: false, interpreter: true)
          Builder.build(document, default_resolve: default_resolve || {}, relay: relay, using: using, interpreter: interpreter)
        end
      end

      # @api private
      module Builder
        extend self

        def build(document, default_resolve:, using: {}, interpreter: true, relay:)
          raise InvalidDocumentError.new('Must provide a document ast.') if !document || !document.is_a?(GraphQL::Language::Nodes::Document)

          if default_resolve.is_a?(Hash)
            default_resolve = ResolveMap.new(default_resolve)
          end

          schema_defns = document.definitions.select { |d| d.is_a?(GraphQL::Language::Nodes::SchemaDefinition) }
          if schema_defns.size > 1
            raise InvalidDocumentError.new('Must provide only one schema definition.')
          end
          schema_definition = schema_defns.first
          types = {}
          directives = {}
          type_resolver = ->(type) { resolve_type(types, type)  }

          document.definitions.each do |definition|
            case definition
            when GraphQL::Language::Nodes::SchemaDefinition
              nil # already handled
            when GraphQL::Language::Nodes::EnumTypeDefinition
              types[definition.name] = build_enum_type(definition, type_resolver)
            when GraphQL::Language::Nodes::ObjectTypeDefinition
              types[definition.name] = build_object_type(definition, type_resolver)
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

          # At this point, if types named by the built in types are _late-bound_ types,
          # that means they were referenced in the schema but not defined in the schema.
          # That's supported for built-in types. (Eg, you can use `String` without defining it.)
          # In that case, insert the concrete type definition now.
          #
          # However, if the type in `types` is a _concrete_ type definition, that means that
          # the document contained an explicit definition of the scalar type.
          # Don't override it in this case.
          GraphQL::Schema::BUILT_IN_TYPES.each do |scalar_name, built_in_scalar|
            existing_type = types[scalar_name]
            if existing_type.is_a?(GraphQL::Schema::LateBoundType)
              types[scalar_name] = built_in_scalar
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

          Class.new(GraphQL::Schema) do
            begin
              # Add these first so that there's some chance of resolving late-bound types
              orphan_types types.values
              query query_root_type
              mutation mutation_root_type
              subscription subscription_root_type
            rescue Schema::UnresolvedLateBoundTypeError  => err
              type_name = err.type.name
              err_backtrace =  err.backtrace
              raise InvalidDocumentError, "Type \"#{type_name}\" not found in document.", err_backtrace
            end

            if default_resolve.respond_to?(:resolve_type)
              def self.resolve_type(*args)
                self.definition_default_resolve.resolve_type(*args)
              end
            else
              def self.resolve_type(*args)
                NullResolveType.call(*args)
              end
            end

            directives directives.values

            if schema_definition
              ast_node(schema_definition)
            end

            if interpreter
              use GraphQL::Execution::Interpreter
              use GraphQL::Analysis::AST
            end

            using.each do |plugin, options|
              if options
                use(plugin, **options)
              else
                use(plugin)
              end
            end

            # Empty `orphan_types` -- this will make unreachable types ... unreachable.
            own_orphan_types.clear

            class << self
              attr_accessor :definition_default_resolve
            end

            self.definition_default_resolve = default_resolve

            def definition_default_resolve
              self.class.definition_default_resolve
            end

            def self.inherited(child_class)
              child_class.definition_default_resolve = self.definition_default_resolve
            end
          end
        end

        NullResolveType = ->(type, obj, ctx) {
          raise(GraphQL::RequiredImplementationMissingError, "Generated Schema cannot use Interface or Union types for execution. Implement resolve_type on your resolver.")
        }

        def build_enum_type(enum_type_definition, type_resolver)
          builder = self
          Class.new(GraphQL::Schema::Enum) do
            graphql_name(enum_type_definition.name)
            description(enum_type_definition.description)
            ast_node(enum_type_definition)
            enum_type_definition.values.each do |enum_value_definition|
              value(enum_value_definition.name,
                value: enum_value_definition.name,
                deprecation_reason: builder.build_deprecation_reason(enum_value_definition.directives),
                description: enum_value_definition.description,
                ast_node: enum_value_definition,
              )
            end
          end
        end

        def build_deprecation_reason(directives)
          deprecated_directive = directives.find{ |d| d.name == 'deprecated' }
          return unless deprecated_directive

          reason = deprecated_directive.arguments.find{ |a| a.name == 'reason' }
          return GraphQL::Schema::Directive::DEFAULT_DEPRECATION_REASON unless reason

          reason.value
        end

        def build_scalar_type(scalar_type_definition, type_resolver, default_resolve:)
          Class.new(GraphQL::Schema::Scalar) do
            graphql_name(scalar_type_definition.name)
            description(scalar_type_definition.description)
            ast_node(scalar_type_definition)

            if default_resolve.respond_to?(:coerce_input)
              def self.coerce_input(val, ctx)
                ctx.schema.definition_default_resolve.coerce_input(self, val, ctx)
              end

              def self.coerce_result(val, ctx)
                ctx.schema.definition_default_resolve.coerce_result(self, val, ctx)
              end
            end
          end
        end

        def build_union_type(union_type_definition, type_resolver)
          Class.new(GraphQL::Schema::Union) do
            graphql_name(union_type_definition.name)
            description(union_type_definition.description)
            possible_types(*union_type_definition.types.map { |type_name| type_resolver.call(type_name) })
            ast_node(union_type_definition)
          end
        end

        def build_object_type(object_type_definition, type_resolver)
          builder = self

          Class.new(GraphQL::Schema::Object) do
            graphql_name(object_type_definition.name)
            description(object_type_definition.description)
            ast_node(object_type_definition)

            object_type_definition.interfaces.each do |interface_name|
              interface_defn = type_resolver.call(interface_name)
              implements(interface_defn)
            end

            builder.build_fields(self, object_type_definition.fields, type_resolver, default_resolve: true)
          end
        end

        def build_input_object_type(input_object_type_definition, type_resolver)
          builder = self
          Class.new(GraphQL::Schema::InputObject) do
            graphql_name(input_object_type_definition.name)
            description(input_object_type_definition.description)
            ast_node(input_object_type_definition)
            builder.build_arguments(self, input_object_type_definition.fields, type_resolver)
          end
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

        NO_DEFAULT_VALUE = {}.freeze

        def build_arguments(type_class, arguments, type_resolver)
          builder = self

          arguments.each do |argument_defn|
            default_value_kwargs = if !argument_defn.default_value.nil?
              { default_value: builder.build_default_value(argument_defn.default_value) }
            else
              NO_DEFAULT_VALUE
            end

            type_class.argument(
              argument_defn.name,
              type: type_resolver.call(argument_defn.type),
              required: false,
              description: argument_defn.description,
              deprecation_reason: builder.build_deprecation_reason(argument_defn.directives),
              ast_node: argument_defn,
              camelize: false,
              method_access: false,
              **default_value_kwargs
            )
          end
        end

        def build_directive(directive_definition, type_resolver)
          builder = self
          Class.new(GraphQL::Schema::Directive) do
            graphql_name(directive_definition.name)
            description(directive_definition.description)
            locations(*directive_definition.locations.map { |location| location.name.to_sym })
            ast_node(directive_definition)
            builder.build_arguments(self, directive_definition.arguments, type_resolver)
          end
        end

        def build_interface_type(interface_type_definition, type_resolver)
          builder = self
          Module.new do
            include GraphQL::Schema::Interface
            graphql_name(interface_type_definition.name)
            description(interface_type_definition.description)
            ast_node(interface_type_definition)

            builder.build_fields(self, interface_type_definition.fields, type_resolver, default_resolve: nil)
          end
        end

        def build_fields(owner, field_definitions, type_resolver, default_resolve:)
          builder = self

          field_definitions.each do |field_definition|
            type_name = resolve_type_name(field_definition.type)
            resolve_method_name = -"resolve_field_#{field_definition.name}"
            schema_field_defn = owner.field(
              field_definition.name,
              description: field_definition.description,
              type: type_resolver.call(field_definition.type),
              null: true,
              connection: type_name.end_with?("Connection"),
              connection_extension: nil,
              deprecation_reason: build_deprecation_reason(field_definition.directives),
              ast_node: field_definition,
              method_conflict_warning: false,
              camelize: false,
              resolver_method: resolve_method_name,
            )

            builder.build_arguments(schema_field_defn, field_definition.arguments, type_resolver)

            # Don't do this for interfaces
            if default_resolve
              owner.class_eval <<-RUBY, __FILE__, __LINE__
                # frozen_string_literal: true
                def #{resolve_method_name}(**args)
                  field_instance = self.class.get_field("#{field_definition.name}")
                  context.schema.definition_default_resolve.call(self.class, field_instance, object, args, context)
                end
              RUBY
            end
          end
        end

        def resolve_type(types, ast_node)
          case ast_node
          when GraphQL::Language::Nodes::TypeName
            type_name = ast_node.name
            types[type_name] ||= GraphQL::Schema::LateBoundType.new(type_name)
          when GraphQL::Language::Nodes::NonNullType
            resolve_type(types, ast_node.of_type).to_non_null_type
          when GraphQL::Language::Nodes::ListType
            resolve_type(types, ast_node.of_type).to_list_type
          else
            raise "Unexpected ast_node: #{ast_node.inspect}"
          end
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
