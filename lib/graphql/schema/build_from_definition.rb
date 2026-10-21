# frozen_string_literal: true
# typed: false
require "graphql/schema/build_from_definition/resolve_map"

module GraphQL
  class Schema
    module BuildFromDefinition
      class << self
        # See [Schema.from_definition](rdoc-ref:Schema.from_definition)
        def from_definition(schema_superclass, definition_string, parser: GraphQL.default_parser, **kwargs)
          if defined?(parser::SchemaParser)
            parser = parser::SchemaParser
          end
          from_document(schema_superclass, parser.parse(definition_string), **kwargs)
        end

        def from_definition_path(schema_superclass, definition_path, parser: GraphQL.default_parser, **kwargs)
          if defined?(parser::SchemaParser)
            parser = parser::SchemaParser
          end
          from_document(schema_superclass, parser.parse_file(definition_path), **kwargs)
        end

        def from_document(schema_superclass, document, default_resolve:, using: {}, base_types: {}, relay: false)
          Builder.build(schema_superclass, document, default_resolve: default_resolve || {}, relay: relay, using: using, base_types: base_types)
        end
      end

      #--
      # @requires_ancestor: Kernel
      module Builder # :nodoc:
        include GraphQL::EmptyObjects
        extend self

        def build(schema_superclass, document, default_resolve:, using: {}, base_types: {}, relay:)
          raise InvalidDocumentError.new('Must provide a document ast.') if !document || !document.is_a?(GraphQL::Language::Nodes::Document)

          base_types = {
            object: GraphQL::Schema::Object,
            interface: GraphQL::Schema::Interface,
            union: GraphQL::Schema::Union,
            scalar: GraphQL::Schema::Scalar,
            enum: GraphQL::Schema::Enum,
            input_object: GraphQL::Schema::InputObject,
          }.merge!(base_types)

          if default_resolve.is_a?(Hash)
            default_resolve = ResolveMap.new(default_resolve)
          end

          schema_defns = document.definitions.select { |d| d.is_a?(GraphQL::Language::Nodes::SchemaDefinition) }
          if schema_defns.size > 1
            raise InvalidDocumentError.new('Must provide only one schema definition.')
          end
          schema_definition = schema_defns.first
          types = {}
          directives = schema_superclass.directives.dup
          # Directive applications are queued while types are built, then applied once every type is complete,
          # because applying a directive coerces its arguments, which requires fully-built input types.
          queued_directives = []
          definitions_by_name = {}
          # Classes for types in this document, made before any type is built so that references to them don't need late-bound types.
          # Interfaces aren't made early because implementing an interface copies some of its configuration.
          type_classes = {}
          document.definitions.each do |d|
            if d.respond_to?(:name)
              definitions_by_name[d.name] ||= d
              if !type_classes.key?(d.name)
                base_type = case d
                when GraphQL::Language::Nodes::ObjectTypeDefinition then base_types[:object]
                when GraphQL::Language::Nodes::EnumTypeDefinition then base_types[:enum]
                when GraphQL::Language::Nodes::InputObjectTypeDefinition then base_types[:input_object]
                when GraphQL::Language::Nodes::UnionTypeDefinition then base_types[:union]
                when GraphQL::Language::Nodes::ScalarTypeDefinition then base_types[:scalar]
                when GraphQL::Language::Nodes::InterfaceTypeDefinition then false
                end
                if !base_type.nil?
                  type_classes[d.name] = base_type && Class.new(base_type) { graphql_name(d.name) }
                end
              end
            end
          end
          type_resolver = TypeResolver.new(types, directives, queued_directives, type_classes) { |type_name|
            types[type_name] ||= if (type_class = type_classes[type_name])
              type_class
            elsif !definitions_by_name.key?(type_name) && (built_in_type = GraphQL::Schema::BUILT_IN_TYPES[type_name])
              built_in_type
            else
              Schema::LateBoundType.new(type_name)
            end
          }
          # Make a different type resolver because directive argument types must be real classes (not late-bound)
          # when queued directives are applied. It builds types eagerly. (Each type registers itself in `types`
          # before building its members, so cycles between input objects terminate.)
          directive_type_resolver = nil
          directive_type_resolver = TypeResolver.new(types, directives, queued_directives, type_classes) { |type_name|
            types[type_name] ||= begin
              defn = definitions_by_name[type_name]
              if defn
                build_definition_from_node(defn, directive_type_resolver, default_resolve, base_types)
              elsif (built_in_defn = GraphQL::Schema::BUILT_IN_TYPES[type_name])
                built_in_defn
              else
                raise "No definition for #{type_name.inspect} found in schema document or built-in types. Add a definition for it or remove it."
              end
            end
          }

          directives.merge!(GraphQL::Schema.default_directives)
          document.definitions.each do |definition|
            if definition.is_a?(GraphQL::Language::Nodes::DirectiveDefinition)
              directives[definition.name] = build_directive(definition, directive_type_resolver)
            end
          end

          # In case any directives referenced built-in types for their arguments:
          replace_late_bound_types_with_built_in(types)

          schema_extensions = nil
          document.definitions.each do |definition|
            case definition
            when GraphQL::Language::Nodes::SchemaDefinition, GraphQL::Language::Nodes::DirectiveDefinition
              nil # already handled
            when GraphQL::Language::Nodes::SchemaExtension,
              GraphQL::Language::Nodes::ScalarTypeExtension,
              GraphQL::Language::Nodes::ObjectTypeExtension,
              GraphQL::Language::Nodes::InterfaceTypeExtension,
              GraphQL::Language::Nodes::UnionTypeExtension,
              GraphQL::Language::Nodes::EnumTypeExtension,
              GraphQL::Language::Nodes::InputObjectTypeExtension
              schema_extensions ||= []
              schema_extensions << definition
            else
              # It's possible that this was already loaded by the directives
              prev_type = types[definition.name]
              if prev_type.nil? || prev_type.is_a?(Schema::LateBoundType) || type_classes[definition.name]
                if definition.is_a?(GraphQL::Language::Nodes::ObjectTypeDefinition) || definition.is_a?(Language::Nodes::InterfaceTypeDefinition)
                  interface_names = definition.interfaces.map(&:name)
                  if !interface_names.empty?
                    transitive_names = interface_names.map { |n| definitions_by_name[n]&.interfaces&.map(&:name) }
                    transitive_names.flatten!
                    transitive_names.compact!
                  else
                    transitive_names = interface_names
                  end
                  if !(missing_transitive_interfaces = transitive_names - interface_names).empty?
                    raise GraphQL::Schema::InvalidDocumentError, "type #{definition.name} is missing one or more transitive interface names: #{missing_transitive_interfaces.join(", ")}. Add them to the type's `implements` list and try again."
                  end
                end

                build_definition_from_node(definition, type_resolver, default_resolve, base_types)
              end
            end
          end

          replace_late_bound_types_with_built_in(types)

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

            if schema_definition.query.nil? &&
                schema_definition.mutation.nil? &&
                schema_definition.subscription.nil?
              # This schema may have been given with directives only,
              # check for defaults:
              query_root_type = types['Query']
              mutation_root_type = types['Mutation']
              subscription_root_type = types['Subscription']
            end
          else
            query_root_type = types['Query']
            mutation_root_type = types['Mutation']
            subscription_root_type = types['Subscription']
          end

          raise InvalidDocumentError.new('Must provide schema definition with query type or a type named Query.') unless query_root_type

          schema_extensions&.each do |ext|
            next if ext.is_a?(GraphQL::Language::Nodes::SchemaExtension)

            built_type = types[ext.name]

            case ext
            when GraphQL::Language::Nodes::ScalarTypeExtension
              build_directives(built_type, ext, type_resolver)
            when GraphQL::Language::Nodes::ObjectTypeExtension
              build_directives(built_type, ext, type_resolver)
              build_fields(built_type, ext.fields, type_resolver, default_resolve: true)
              build_interfaces(built_type, ext.interfaces, type_resolver)
            when GraphQL::Language::Nodes::InterfaceTypeExtension
              build_directives(built_type, ext, type_resolver)
              build_fields(built_type, ext.fields, type_resolver, default_resolve: nil)
              build_interfaces(built_type, ext.interfaces, type_resolver)
            when GraphQL::Language::Nodes::UnionTypeExtension
              build_directives(built_type, ext, type_resolver)
              built_type.possible_types(*ext.types.map { |type_name| type_resolver.call(type_name) })
            when GraphQL::Language::Nodes::EnumTypeExtension
              build_directives(built_type, ext, type_resolver)
              build_values(built_type, ext.values, type_resolver)
            when GraphQL::Language::Nodes::InputObjectTypeExtension
              build_directives(built_type, ext, type_resolver)
              build_arguments(built_type, ext.fields, type_resolver)
            end
          end

          # All types are built now, so directive arguments can be coerced
          apply_queued_directives(queued_directives)

          builder = self

          found_types = types.values
          object_types = found_types.select { |t| t.is_a?(Class) && t < GraphQL::Schema::Object }
          schema_class = Class.new(schema_superclass) do
            #: self as singleton(GraphQL::Schema)
            begin
              # Add these first so that there's some chance of resolving late-bound types
              add_type_and_traverse(found_types, root: false)
              # Without visibility, this would only re-traverse types that were just added
              # (and `own_orphan_types` is cleared below), so it can be skipped.
              if use_visibility_profile? || visibility
                orphan_types(object_types)
              end
              query query_root_type
              mutation mutation_root_type
              subscription subscription_root_type
            rescue Schema::UnresolvedLateBoundTypeError  => err
              type_name = err.type.name
              err_backtrace =  err.backtrace
              raise InvalidDocumentError, "Type \"#{type_name}\" not found in document.", err_backtrace
            end

            object_types.each do |t|
              t.interfaces.each do |int_t|
                if int_t.is_a?(LateBoundType)
                  int_t = types[int_t.graphql_name]
                  t.implements(int_t)
                end
                int_t.orphan_types(t)
              end
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
              builder.build_directives(self, schema_definition, type_resolver)
              builder.apply_queued_directives(queued_directives)
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
              super
            end
          end

          schema_extensions&.each do |ext|
            if ext.is_a?(GraphQL::Language::Nodes::SchemaExtension)
              build_directives(schema_class, ext, type_resolver)
            end
          end
          apply_queued_directives(queued_directives)

          directives.each_value do |dir_class|
            if dir_class.respond_to?(:coerced_arguments_cache=) && dir_class.coerced_arguments_cache
              dir_class.coerced_arguments_cache = nil
            end
          end

          schema_class
        end

        NullResolveType = ->(type, obj, ctx) {
          raise(GraphQL::RequiredImplementationMissingError, "Generated Schema cannot use Interface or Union types for execution. Implement resolve_type on your resolver.")
        }

        def build_definition_from_node(definition, type_resolver, default_resolve, base_types)
          case definition
          when GraphQL::Language::Nodes::EnumTypeDefinition
            build_enum_type(definition, type_resolver, base_types[:enum])
          when GraphQL::Language::Nodes::ObjectTypeDefinition
            build_object_type(definition, type_resolver, base_types[:object])
          when GraphQL::Language::Nodes::InterfaceTypeDefinition
            build_interface_type(definition, type_resolver, base_types[:interface])
          when GraphQL::Language::Nodes::UnionTypeDefinition
            build_union_type(definition, type_resolver, base_types[:union])
          when GraphQL::Language::Nodes::ScalarTypeDefinition
            build_scalar_type(definition, type_resolver, base_types[:scalar], default_resolve: default_resolve)
          when GraphQL::Language::Nodes::InputObjectTypeDefinition
            build_input_object_type(definition, type_resolver, base_types[:input_object])
          when GraphQL::Language::Nodes::DirectiveDefinition
            build_directive(definition, type_resolver)
          end
        end

        # Modify `types`, replacing any late-bound references to built-in types
        # with their actual definitions.
        #
        # (Schema definitions are allowed to reference those built-ins without redefining them.)
        #
        # **Returns**
        #
        # - `Object` — void
        #
        # :call-seq:
        #   replace_late_bound_types_with_built_in(types) -> Object
        def replace_late_bound_types_with_built_in(types)
          GraphQL::Schema::BUILT_IN_TYPES.each do |scalar_name, built_in_scalar|
            existing_type = types[scalar_name]
            if existing_type.is_a?(GraphQL::Schema::LateBoundType)
              types[scalar_name] = built_in_scalar
            end
          end
        end

        # Apply `ast_node`'s directives to `definition`. If any of those directives has arguments,
        # they're queued for {apply_queued_directives} because coercing arguments requires fully-built types.
        # Directives without arguments are applied right away, since some (like `@oneOf`) affect how the rest of the type is built.
        def build_directives(definition, ast_node, type_resolver)
          return if ast_node.directives.empty?

          if ast_node.directives.all? { |dir_node| dir_node.name == "deprecated" || type_resolver.directive_without_arguments?(dir_node.name) }
            apply_directives(definition, ast_node, type_resolver)
          else
            type_resolver.queued_directives << [definition, ast_node, type_resolver]
          end
        end

        def apply_queued_directives(queued_directives)
          until queued_directives.empty?
            apply_directives(*queued_directives.shift)
          end
        end

        def apply_directives(definition, ast_node, type_resolver)
          is_schema = definition.respond_to?(:schema_directive)
          ast_node.directives.each do |dir_node|
            # This is handled using `deprecation_reason`
            next if dir_node.name == "deprecated"
            dir_class = type_resolver.call(dir_node.name)
            if dir_class.nil?
              raise ArgumentError, "No definition for @#{dir_node.name} #{ast_node.respond_to?(:name) ? "on #{ast_node.name} " : ""}at #{ast_node.line}:#{ast_node.col}"
            end
            options = args_to_kwargs(dir_class, dir_node)
            if is_schema
              definition.schema_directive(dir_class, **options)
            else
              definition.directive(dir_class, **options)
            end
          end
        end

        def args_to_kwargs(arg_owner, node)
          if node.respond_to?(:arguments)
            kwargs = {}
            node.arguments.each do |arg_node|
              arg_defn = arg_owner.get_argument(arg_node.name)
              kwargs[arg_defn.keyword] = args_to_kwargs(arg_defn.type.unwrap, arg_node.value)
            end
            kwargs
          elsif node.is_a?(Array)
            node.map { |n| args_to_kwargs(arg_owner, n) }
          elsif node.is_a?(Language::Nodes::Enum)
            node.name
          else
            # scalar
            node
          end
        end

        def build_enum_type(enum_type_definition, type_resolver, base_type)
          type_class = type_resolver.type_class(enum_type_definition.name, base_type) #: singleton(GraphQL::Schema::Enum)
          type_resolver.register(type_class)
          build_directives(type_class, enum_type_definition, type_resolver)
          type_class.description(enum_type_definition.description)
          type_class.ast_node(enum_type_definition)
          build_values(type_class, enum_type_definition.values, type_resolver)
          type_class
        end

        def build_values(type_class, enum_value_definitions, type_resolver)
          enum_value_definitions.each do |enum_value_definition|
            enum_value = type_class.value(enum_value_definition.name,
              value: enum_value_definition.name,
              deprecation_reason: build_deprecation_reason(enum_value_definition.directives),
              description: enum_value_definition.description,
              ast_node: enum_value_definition,
            )
            build_directives(enum_value, enum_value_definition, type_resolver)
          end
        end

        def build_deprecation_reason(directives)
          return if directives.empty?
          directives.each do |d|
            if d.name == "deprecated"
              d.arguments.each do |a|
                if a.name == "reason"
                  return a.value
                end
              end
              return GraphQL::Schema::Directive::DEFAULT_DEPRECATION_REASON
            end
          end
          nil
        end

        def build_scalar_type(scalar_type_definition, type_resolver, base_type, default_resolve:)
          type_class = type_resolver.type_class(scalar_type_definition.name, base_type) #: singleton(GraphQL::Schema::Scalar)
          type_resolver.register(type_class)
          type_class.description(scalar_type_definition.description)
          type_class.ast_node(scalar_type_definition)
          build_directives(type_class, scalar_type_definition, type_resolver)

          if default_resolve.respond_to?(:coerce_input)
            # Put these method definitions in another method to avoid retaining `type_resolve`
            # from this method's bindiing
            build_scalar_type_coerce_method(type_class, :coerce_input, default_resolve)
            build_scalar_type_coerce_method(type_class, :coerce_result, default_resolve)
          end
          type_class
        end

        def build_scalar_type_coerce_method(scalar_class, method_name, default_definition_resolve)
          scalar_class.define_singleton_method(method_name) do |val, ctx|
            default_definition_resolve.public_send(method_name, self, val, ctx)
          end
        end

        def build_union_type(union_type_definition, type_resolver, base_type)
          type_class = type_resolver.type_class(union_type_definition.name, base_type) #: singleton(GraphQL::Schema::Union)
          type_resolver.register(type_class)
          type_class.description(union_type_definition.description)
          type_class.possible_types(*union_type_definition.types.map { |type_name| type_resolver.call(type_name) })
          type_class.ast_node(union_type_definition)
          build_directives(type_class, union_type_definition, type_resolver)
          type_class
        end

        def build_object_type(object_type_definition, type_resolver, base_type)
          type_class = type_resolver.type_class(object_type_definition.name, base_type) #: singleton(GraphQL::Schema::Object)
          type_resolver.register(type_class)
          type_class.description(object_type_definition.description)
          type_class.ast_node(object_type_definition)
          build_directives(type_class, object_type_definition, type_resolver)
          build_interfaces(type_class, object_type_definition.interfaces, type_resolver)
          build_fields(type_class, object_type_definition.fields, type_resolver, default_resolve: true)
          type_class
        end

        def build_interfaces(type_class, interface_names, type_resolver)
          interface_names.each do |interface_name|
            type_class.implements(type_resolver.call(interface_name))
          end
        end

        def build_input_object_type(input_object_type_definition, type_resolver, base_type)
          type_class = type_resolver.type_class(input_object_type_definition.name, base_type) #: singleton(GraphQL::Schema::InputObject)
          type_resolver.register(type_class)
          type_class.description(input_object_type_definition.description)
          type_class.ast_node(input_object_type_definition)
          build_directives(type_class, input_object_type_definition, type_resolver)
          build_arguments(type_class, input_object_type_definition.fields, type_resolver)
          type_class
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

        def build_arguments(type_class, arguments, type_resolver)
          builder = self

          arguments.each do |argument_defn|
            default_value_kwargs = if !argument_defn.default_value.nil?
              { default_value: builder.build_default_value(argument_defn.default_value) }
            else
              EMPTY_HASH
            end

            argument = type_class.argument(
              argument_defn.name,
              type: type_resolver.call(argument_defn.type),
              required: false,
              description: argument_defn.description,
              deprecation_reason: builder.build_deprecation_reason(argument_defn.directives),
              ast_node: argument_defn,
              camelize: false,
              **default_value_kwargs
            )
            builder.build_directives(argument, argument_defn, type_resolver)
          end
        end

        def build_directive(directive_definition, type_resolver)
          builder = self
          Class.new(GraphQL::Schema::Directive) do
            graphql_name(directive_definition.name)
            description(directive_definition.description)
            repeatable(directive_definition.repeatable)
            locations(*directive_definition.locations.map { |location| location.name.to_sym })
            ast_node(directive_definition)
            builder.build_arguments(self, directive_definition.arguments, type_resolver)
            self.coerced_arguments_cache = {}
          end
        end

        def build_interface_type(interface_type_definition, type_resolver, base_type)
          builder = self
          Module.new do
            #: self as GraphQL::Schema::Member::interface_definition
            include base_type
            graphql_name(interface_type_definition.name)
            type_resolver.register(self)
            description(interface_type_definition.description)
            builder.build_interfaces(self, interface_type_definition.interfaces, type_resolver)
            ast_node(interface_type_definition)
            builder.build_directives(self, interface_type_definition, type_resolver)

            builder.build_fields(self, interface_type_definition.fields, type_resolver, default_resolve: nil)
          end
        end

        def build_fields(owner, field_definitions, type_resolver, default_resolve:)
          builder = self
          # If `owner.field` isn't customized, make fields directly. It's the same, but faster.
          field_class = owner.method(:field).owner.equal?(GraphQL::Schema::Member::HasFields) ? owner.field_class : nil
          resolve_method_names = type_resolver.field_resolve_methods.method_names
          field_definitions.each do |field_definition|
            resolve_method_name = resolve_method_names[field_definition.name]
            if field_class
              schema_field_defn = field_class.new(
                name: field_definition.name,
                owner: owner,
                description: field_definition.description,
                type: type_resolver.call(field_definition.type),
                null: true,
                connection_extension: nil,
                deprecation_reason: build_deprecation_reason(field_definition.directives),
                ast_node: field_definition,
                method_conflict_warning: false,
                camelize: false,
                resolver_method: resolve_method_name,
                resolve_batch: resolve_method_name,
              )
              owner.add_field(schema_field_defn)
            else
              schema_field_defn = owner.field(
                field_definition.name,
                description: field_definition.description,
                type: type_resolver.call(field_definition.type),
                null: true,
                connection_extension: nil,
                deprecation_reason: build_deprecation_reason(field_definition.directives),
                ast_node: field_definition,
                method_conflict_warning: false,
                camelize: false,
                resolver_method: resolve_method_name,
                resolve_batch: resolve_method_name,
              )
            end

            builder.build_directives(schema_field_defn, field_definition, type_resolver)
            builder.build_arguments(schema_field_defn, field_definition.arguments, type_resolver)

            # Don't do this for interfaces
            if default_resolve
              define_field_resolve_method(owner, resolve_method_name, field_definition.name, type_resolver)
            end
          end
        end

        def define_field_resolve_method(owner, method_name, field_name, type_resolver)
          resolve_methods = type_resolver.field_resolve_methods
          resolve_methods.field_names[method_name.to_sym] = field_name
          owner.define_method(method_name, &resolve_methods.instance_method_proc)
          owner.define_singleton_method(method_name, &resolve_methods.singleton_method_proc)
        end

        # Every field's resolve methods share these procs. They use the method's name to find the field.
        class FieldResolveMethods
          def initialize
            @method_names = Hash.new { |h, field_name| h[field_name] = -"resolve_field_#{field_name}" }
            field_names = @field_names = {}
            @instance_method_proc = proc { |**args|
              #: self as GraphQL::Schema::Object
              owner = self.class
              field_instance = context.types.field(owner, field_names[__method__])
              context.schema.definition_default_resolve.call(owner, field_instance, object, args, context)
            }
            @singleton_method_proc = proc { |objects, context, **args|
              field_instance = context.types.field(self, field_names[__method__])
              objects.map do |object|
                context.schema.definition_default_resolve.call(self, field_instance, object, args, context)
              end
            }
          end

          # Field names by resolve method name
          attr_reader :field_names

          # Resolve method names by field name
          attr_reader :method_names

          attr_reader :instance_method_proc, :singleton_method_proc
        end

        class TypeResolver
          def initialize(lookup_hash, directives, queued_directives, type_classes, &missing_type_handler)
            @lookup_hash = lookup_hash
            @directives = directives
            @queued_directives = queued_directives
            @type_classes = type_classes
            @missing_type_handler = missing_type_handler
          end

          # The class made ahead of time for `type_name` (returned once, to be built), or a new subclass of `base_type`
          def type_class(type_name, base_type)
            @type_classes.delete(type_name) || Class.new(base_type) { graphql_name(type_name) }
          end

          # Directive applications waiting for {Builder#apply_queued_directives}
          attr_reader :queued_directives

          def field_resolve_methods
            @field_resolve_methods ||= FieldResolveMethods.new
          end

          # Add `type` to the lookup hash. Types call this before building their members, so that references back to them (including cycles) find this type.
          def register(type)
            @lookup_hash[type.graphql_name] = type
          end

          # The already-defined directive class named `name`, or `nil` if there isn't one yet
          def directive_class(name)
            @directives[name]
          end

          def directive_without_arguments?(name)
            @directives_without_arguments ||= {}
            if @directives_without_arguments.key?(name)
              @directives_without_arguments[name]
            else
              dir_class = @directives[name]
              # Don't cache unknown directives, they might be defined later
              dir_class ? (@directives_without_arguments[name] = dir_class.all_argument_definitions.empty?) : false
            end
          end

          def call(ast_node)
            case ast_node
            when GraphQL::Language::Nodes::TypeName
              type_name = ast_node.name
              if @lookup_hash.key?(type_name)
                @lookup_hash[type_name]
              else
                @missing_type_handler.call(type_name)
              end
            when GraphQL::Language::Nodes::NonNullType
              call(ast_node.of_type).to_non_null_type
            when GraphQL::Language::Nodes::ListType
              call(ast_node.of_type).to_list_type
            when String
              @directives[ast_node] ||= @missing_type_handler.call(ast_node)
            else
              raise "Unexpected ast_node: #{ast_node.inspect}"
            end
          end
        end
      end

      private_constant :Builder
    end
  end
end
