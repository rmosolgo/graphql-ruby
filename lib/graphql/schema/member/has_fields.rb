# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      # Shared code for Objects, Interfaces, Mutations, Subscriptions
      module HasFields
        include EmptyObjects
        # Add a field to this object or interface with the given definition
        # @param name_positional [Symbol] The underscore-cased version of this field name (will be camelized for the GraphQL API); `name:` keyword is also accepted
        # @param type_positional [Class, GraphQL::BaseType, Array] The return type of this field; `type:` keyword is also accepted
        # @param desc_positional [String] Field description; `description:` keyword is also accepted
        # @option kwargs [Symbol] :name The underscore-cased version of this field name (will be camelized for the GraphQL API); positional argument also accepted
        # @option kwargs [Class, GraphQL::BaseType, Array] :type The return type of this field; positional argument is also accepted
        # @option kwargs [Boolean] :null (defaults to `true`) `true` if this field may return `null`, `false` if it is never `null`
        # @option kwargs [String] :description Field description; positional argument also accepted
        # @option kwargs [String] :comment Field comment
        # @option kwargs [String] :deprecation_reason If present, the field is marked "deprecated" with this message
        # @option kwargs [Symbol] :method The method to call on the underlying object to resolve this field (defaults to `name`)
        # @option kwargs [String, Symbol] :hash_key The hash key to lookup on the underlying object (if its a Hash) to resolve this field (defaults to `name` or `name.to_s`)
        # @option kwargs [Array<String, Symbol>] :dig The nested hash keys to lookup on the underlying hash to resolve this field using dig
        # @option kwargs [Symbol] :resolver_method The method on the type to call to resolve this field (defaults to `name`)
        # @option kwargs [Symbol] :resolve_static Used by {Schema.execute_batching} to produce a single value, shared by all objects which resolve this field. Called on the owner type class with `context, **arguments`
        # @option kwargs [Symbol] :resolve_batch Used by {Schema.execute_batching} map `objects` to a same-sized Array of results. Called on the owner type class with `objects, context, **arguments`.
        # @option kwargs [Symbol] :resolve_each Used by {Schema.execute_batching} to get a value value for each item. Called on the owner type class with `object, context, **arguments`.
        # @option kwargs [Boolean] :connection `true` if this field should get automagic connection behavior; default is to infer by `*Connection` in the return type name
        # @option kwargs [Class] :connection_extension The extension to add, to implement connections. If `nil`, no extension is added.
        # @option kwargs [Integer, nil] :max_page_size For connections, the maximum number of items to return from this field, or `nil` to allow unlimited results.
        # @option kwargs [Integer, nil] :default_page_size For connections, the default number of items to return from this field, or `nil` to return unlimited results.
        # @option kwargs [Boolean] :introspection If true, this field will be marked as `#introspection?` and the name may begin with `__`
        # @option kwargs [{String=>GraphQL::Schema::Argument, Hash}] :arguments Arguments for this field (may be added in the block, also)
        # @option kwargs [Boolean] :camelize If true, the field name will be camelized when building the schema
        # @option kwargs [Numeric] :complexity When provided, set the complexity for this field
        # @option kwargs [Boolean] :scope If true, the return type's `.scope_items` method will be called on the return value
        # @option kwargs [Symbol, String] :subscription_scope A key in `context` which will be used to scope subscription payloads
        # @option kwargs [Array<Class, Hash<Class => Object>>] :extensions Named extensions to apply to this field (see also {#extension})
        # @option kwargs [Hash{Class => Hash}] :directives Directives to apply to this field
        # @option kwargs [Boolean] :trace If true, a {GraphQL::Tracing} tracer will measure this scalar field
        # @option kwargs [Boolean] :broadcastable Whether or not this field can be distributed in subscription broadcasts
        # @option kwargs [Language::Nodes::FieldDefinition, nil] :ast_node If this schema was parsed from definition, this AST node defined the field
        # @option kwargs [Boolean] :method_conflict_warning If false, skip the warning if this field's method conflicts with a built-in method
        # @option kwargs [Array<Hash>] :validates Configurations for validating this field
        # @option kwargs [Object] :fallback_value A fallback value if the method is not defined
        # @option kwargs [Class<GraphQL::Schema::Mutation>] :mutation
        # @option kwargs [Class<GraphQL::Schema::Resolver>] :resolver
        # @option kwargs [Class<GraphQL::Schema::Subscription>] :subscription
        # @option kwargs [Boolean] :dynamic_introspection (Private, used by GraphQL-Ruby)
        # @option kwargs [Boolean] :relay_node_field (Private, used by GraphQL-Ruby)
        # @option kwargs [Boolean] :relay_nodes_field (Private, used by GraphQL-Ruby)
        # @option kwargs [Array<:ast_node, :parent, :lookahead, :owner, :execution_errors, :graphql_name, :argument_details, Symbol>] :extras Extra arguments to be injected into the resolver for this field
        # @param kwargs [Hash] Keywords for defining the field. Any not documented here will be passed to your base field class where they must be handled.
        # @param definition_block [Proc] an additional block for configuring the field. Receive the field as a block param, or, if no block params are defined, then the block is `instance_eval`'d on the new {Field}.
        # @yieldparam field [GraphQL::Schema::Field] The newly-created field instance
        # @yieldreturn [void]
        # @return [GraphQL::Schema::Field]
        def field(name_positional = nil, type_positional = nil, desc_positional = nil, **kwargs, &definition_block)
          resolver = kwargs.delete(:resolver)
          mutation = kwargs.delete(:mutation)
          subscription = kwargs.delete(:subscription)
          if (resolver_class = resolver || mutation || subscription)
            # Add a reference to that parent class
            kwargs[:resolver_class] = resolver_class
          end

          kwargs[:name] ||= name_positional
          if !type_positional.nil?
            if desc_positional
              if kwargs[:description]
                raise ArgumentError, "Provide description as a positional argument or `description:` keyword, but not both (#{desc_positional.inspect}, #{kwargs[:description].inspect})"
              end

              kwargs[:description] = desc_positional
              kwargs[:type] = type_positional
            elsif (resolver || mutation) && type_positional.is_a?(String)
              # The return type should be copied from the resolver, and the second positional argument is the description
              kwargs[:description] = type_positional
            else
              kwargs[:type] = type_positional
            end

            if type_positional.is_a?(Class) && type_positional < GraphQL::Schema::Mutation
              raise ArgumentError, "Use `field #{name_positional.inspect}, mutation: Mutation, ...` to provide a mutation to this field instead"
            end
          end

          kwargs[:owner] = self
          field_defn = field_class.new(**kwargs, &definition_block)
          add_field(field_defn)
          field_defn
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
          if method_conflict_warning &&
              CONFLICT_FIELD_NAMES.include?(field_defn.resolver_method) &&
              field_defn.original_name == field_defn.resolver_method &&
              field_defn.original_name == field_defn.method_sym &&
              field_defn.hash_key == NOT_CONFIGURED &&
              field_defn.dig_keys.nil?
            warn(conflict_field_name_warning(field_defn))
          end
          prev_defn = own_fields[field_defn.name]

          case prev_defn
          when nil
            own_fields[field_defn.name] = field_defn
          when Array
            prev_defn << field_defn
          when GraphQL::Schema::Field
            own_fields[field_defn.name] = [prev_defn, field_defn]
          else
            raise "Invariant: unexpected previous field definition for #{field_defn.name.inspect}: #{prev_defn.inspect}"
          end

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
          type = self
          field field_name, "ID", **kwargs, null: false
          define_method(field_name) do
            context.schema.id_from_object(object, type, context)
          end
        end

        # @param new_has_no_fields [Boolean] Call with `true` to make this Object type ignore the requirement to have any defined fields.
        # @return [void]
        def has_no_fields(new_has_no_fields)
          @has_no_fields = new_has_no_fields
          nil
        end

        # @return [Boolean] `true` if `has_no_fields(true)` was configued
        def has_no_fields?
          @has_no_fields
        end

        # @return [Hash<String => GraphQL::Schema::Field, Array<GraphQL::Schema::Field>>] Fields defined on this class _specifically_, not parent classes
        def own_fields
          @own_fields ||= {}
        end

        def all_field_definitions
          all_fields = {}
          ancestors.reverse_each do |ancestor|
            if ancestor.respond_to?(:own_fields)
              all_fields.merge!(ancestor.own_fields)
            end
          end
          all_fields = all_fields.values
          all_fields.flatten!
          all_fields
        end

        module InterfaceMethods
          def get_field(field_name, context = GraphQL::Query::NullContext.instance)
            warden = Warden.from_context(context)
            skip_visible = context.respond_to?(:types) && context.types.is_a?(GraphQL::Schema::Visibility::Profile)
            for ancestor in ancestors
              if ancestor.respond_to?(:own_fields) &&
                  (f_entry = ancestor.own_fields[field_name]) &&
                  (skip_visible || (f_entry = Warden.visible_entry?(:visible_field?, f_entry, context, warden)))
                return f_entry
              end
            end
            nil
          end

          # @return [Hash<String => GraphQL::Schema::Field>] Fields on this object, keyed by name, including inherited fields
          def fields(context = GraphQL::Query::NullContext.instance)
            warden = Warden.from_context(context)
            # Local overrides take precedence over inherited fields
            visible_fields = {}
            for ancestor in ancestors
              if ancestor.respond_to?(:own_fields)
                ancestor.own_fields.each do |field_name, fields_entry|
                  # Choose the most local definition that passes `.visible?` --
                  # stop checking for fields by name once one has been found.
                  if !visible_fields.key?(field_name) && (f = Warden.visible_entry?(:visible_field?, fields_entry, context, warden))
                    visible_fields[field_name] = f.ensure_loaded
                  end
                end
              end
            end
            visible_fields
          end
        end

        module ObjectMethods
          def get_field(field_name, context = GraphQL::Query::NullContext.instance)
            # Objects need to check that the interface implementation is visible, too
            warden = Warden.from_context(context)
            ancs = ancestors
            skip_visible = context.respond_to?(:types) && context.types.is_a?(GraphQL::Schema::Visibility::Profile)
            i = 0
            while (ancestor = ancs[i])
              if ancestor.respond_to?(:own_fields) &&
                  visible_interface_implementation?(ancestor, context, warden) &&
                  (f_entry = ancestor.own_fields[field_name]) &&
                  (skip_visible || (f_entry = Warden.visible_entry?(:visible_field?, f_entry, context, warden)))
                return (skip_visible ? f_entry : f_entry.ensure_loaded)
              end
              i += 1
            end
            nil
          end

          # @return [Hash<String => GraphQL::Schema::Field>] Fields on this object, keyed by name, including inherited fields
          def fields(context = GraphQL::Query::NullContext.instance)
            # Objects need to check that the interface implementation is visible, too
            warden = Warden.from_context(context)
            # Local overrides take precedence over inherited fields
            visible_fields = {}
            had_any_fields_at_all = false
            for ancestor in ancestors
              if ancestor.respond_to?(:own_fields) && visible_interface_implementation?(ancestor, context, warden)
                ancestor.own_fields.each do |field_name, fields_entry|
                  had_any_fields_at_all = true
                  # Choose the most local definition that passes `.visible?` --
                  # stop checking for fields by name once one has been found.
                  if !visible_fields.key?(field_name) && (f = Warden.visible_entry?(:visible_field?, fields_entry, context, warden))
                    visible_fields[field_name] = f.ensure_loaded
                  end
                end
              end
            end
            if !had_any_fields_at_all && !has_no_fields?
              warn(GraphQL::Schema::Object::FieldsAreRequiredError.new(self).message + "\n\nThis will raise an error in a future GraphQL-Ruby version.")
            end
            visible_fields
          end
        end

        def self.included(child_class)
          # Included in an interface definition methods module
          child_class.include(InterfaceMethods)
          super
        end

        def self.extended(child_class)
          child_class.extend(ObjectMethods)
          super
        end

        private

        def inherited(subclass)
          super
          subclass.class_exec do
            @own_fields ||= nil
            @field_class ||= nil
            @has_no_fields ||= false
          end
        end

        # If `type` is an interface, and `self` has a type membership for `type`, then make sure it's visible.
        def visible_interface_implementation?(type, context, warden)
          if type.respond_to?(:kind) && type.kind.interface?
            implements_this_interface = false
            implementation_is_visible = false
            warden.interface_type_memberships(self, context).each do |tm|
              if tm.abstract_type == type
                implements_this_interface ||= true
                if warden.visible_type_membership?(tm, context)
                  implementation_is_visible = true
                  break
                end
              end
            end
            # It's possible this interface came by way of `include` in another interface which this
            # object type _does_ implement, and that's ok
            implements_this_interface ? implementation_is_visible : true
          else
            # If there's no implementation, then we're looking at Ruby-style inheritance instead
            true
          end
        end

        # @param field_defn [GraphQL::Schema::Field]
        # @return [String] A warning to give when this field definition might conflict with a built-in method
        def conflict_field_name_warning(field_defn)
          "#{self.graphql_name}'s `field :#{field_defn.original_name}` conflicts with a built-in method, use `resolver_method:` to pick a different resolver method for this field (for example, `resolver_method: :resolve_#{field_defn.resolver_method}` and `def resolve_#{field_defn.resolver_method}`). Or use `method_conflict_warning: false` to suppress this warning."
        end
      end
    end
  end
end
