# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      # Shared code for Object and Interface
      module HasFields
        # Add a field to this object or interface with the given definition
        # @param name [Symbol] The underscore-cased version of this field name (will be camelized for the GraphQL API)
        # @param type [Class, GraphQL::BaseType, Array] The return type of this field
        # @param owner [Class] The type that this field belongs to
        # @param null [Boolean] `true` if this field may return `null`, `false` if it is never `null`
        # @param description [String] Field description
        # @param deprecation_reason [String] If present, the field is marked "deprecated" with this message
        # @param method [Symbol] The method to call on the underlying object to resolve this field (defaults to `name`)
        # @param hash_key [String, Symbol] The hash key to lookup on the underlying object (if its a Hash) to resolve this field (defaults to `name` or `name.to_s`)
        # @param resolver_method [Symbol] The method on the type to call to resolve this field (defaults to `name`)
        # @param connection [Boolean] `true` if this field should get automagic connection behavior; default is to infer by `*Connection` in the return type name
        # @param connection_extension [Class] The extension to add, to implement connections. If `nil`, no extension is added.
        # @param max_page_size [Integer, nil] For connections, the maximum number of items to return from this field, or `nil` to allow unlimited results.
        # @param introspection [Boolean] If true, this field will be marked as `#introspection?` and the name may begin with `__`
        # @param resolve [<#call(obj, args, ctx)>] **deprecated** for compatibility with <1.8.0
        # @param field [GraphQL::Field, GraphQL::Schema::Field] **deprecated** for compatibility with <1.8.0
        # @param function [GraphQL::Function] **deprecated** for compatibility with <1.8.0
        # @param resolver_class [Class] (Private) A {Schema::Resolver} which this field was derived from. Use `resolver:` to create a field with a resolver.
        # @param arguments [{String=>GraphQL::Schema::Argument, Hash}] Arguments for this field (may be added in the block, also)
        # @param camelize [Boolean] If true, the field name will be camelized when building the schema
        # @param complexity [Numeric] When provided, set the complexity for this field
        # @param scope [Boolean] If true, the return type's `.scope_items` method will be called on the return value
        # @param subscription_scope [Symbol, String] A key in `context` which will be used to scope subscription payloads
        # @param extensions [Array<Class, Hash<Class => Object>>] Named extensions to apply to this field (see also {#extension})
        # @param directives [Hash{Class => Hash}] Directives to apply to this field
        # @param trace [Boolean] If true, a {GraphQL::Tracing} tracer will measure this scalar field
        # @param broadcastable [Boolean] Whether or not this field can be distributed in subscription broadcasts
        # @param ast_node [Language::Nodes::FieldDefinition, nil] If this schema was parsed from definition, this AST node defined the field
        # @param method_conflict_warning [Boolean] If false, skip the warning if this field's method conflicts with a built-in method
        # @param validates [Array<Hash>] Configurations for validating this field
        # @param legacy_edge_class [Class, nil] (DEPRECATED) If present, pass this along to the legacy field definition
        # @return [GraphQL::Schema::Field]
        # @note Keep this type definition in sync with GraphQL::Schema::Field#initialize
        def field(*args, **kwargs, &block)
          field_defn = field_class.from_options(*args, owner: self, **kwargs, &block)
          add_field(field_defn)
          field_defn
        end

        # @return [Hash<String => GraphQL::Schema::Field>] Fields on this object, keyed by name, including inherited fields
        def fields
          # Local overrides take precedence over inherited fields
          all_fields = {}
          ancestors.reverse_each do |ancestor|
            if ancestor.respond_to?(:own_fields)
              all_fields.merge!(ancestor.own_fields)
            end
          end
          all_fields
        end

        def get_field(field_name)
          if (f = own_fields[field_name])
            f
          else
            for ancestor in ancestors
              if ancestor.respond_to?(:own_fields) && f = ancestor.own_fields[field_name]
                return f
              end
            end
            nil
          end
        end

        # A list of Ruby keywords.
        #
        # @api private
        RUBY_KEYWORDS = [:class, :module, :def, :undef, :begin, :rescue, :ensure, :end, :if, :unless, :then, :elsif, :else, :case, :when, :while, :until, :for, :break, :next, :redo, :retry, :in, :do, :return, :yield, :super, :self, :nil, :true, :false, :and, :or, :not, :alias, :defined?, :BEGIN, :END, :__LINE__, :__FILE__]

        # A list of GraphQL-Ruby keywords.
        #
        # @api private
        GRAPHQL_RUBY_KEYWORDS = [:context, :object, :raw_value]

        # A list of field names that we should advise users to pick a different
        # resolve method name.
        #
        # @api private
        CONFLICT_FIELD_NAMES = Set.new(GRAPHQL_RUBY_KEYWORDS + RUBY_KEYWORDS + Object.instance_methods)

        # Register this field with the class, overriding a previous one if needed.
        # @param field_defn [GraphQL::Schema::Field]
        # @return [void]
        def add_field(field_defn, method_conflict_warning: field_defn.method_conflict_warning?)
          # Check that `field_defn.original_name` equals `resolver_method` and `method_sym` --
          # that shows that no override value was given manually.
          if method_conflict_warning && CONFLICT_FIELD_NAMES.include?(field_defn.resolver_method) && field_defn.original_name == field_defn.resolver_method && field_defn.original_name == field_defn.method_sym
            warn(conflict_field_name_warning(field_defn))
          end
          own_fields[field_defn.name] = field_defn
          nil
        end

        # @return [Class] The class to initialize when adding fields to this kind of schema member
        def field_class(new_field_class = nil)
          if new_field_class
            @field_class = new_field_class
          elsif defined?(@field_class) && @field_class
            @field_class
          else
            find_inherited_value(:field_class, GraphQL::Schema::Field)
          end
        end

        def global_id_field(field_name, **kwargs)
          id_resolver = GraphQL::Relay::GlobalIdResolve.new(type: self)
          field field_name, "ID", **kwargs, null: false
          define_method(field_name) do
            id_resolver.call(object, {}, context)
          end
        end

        # @return [Array<GraphQL::Schema::Field>] Fields defined on this class _specifically_, not parent classes
        def own_fields
          @own_fields ||= {}
        end

        private

        # @param [GraphQL::Schema::Field]
        # @return [String] A warning to give when this field definition might conflict with a built-in method
        def conflict_field_name_warning(field_defn)
          "#{self.graphql_name}'s `field :#{field_defn.original_name}` conflicts with a built-in method, use `resolver_method:` to pick a different resolver method for this field (for example, `resolver_method: :resolve_#{field_defn.resolver_method}` and `def resolve_#{field_defn.resolver_method}`). Or use `method_conflict_warning: false` to suppress this warning."
        end
      end
    end
  end
end
