# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      # Shared code for Objects, Interfaces, Mutations, Subscriptions
      module HasFields
        # Add a field to this object or interface with the given definition
        # @see {GraphQL::Schema::Field#initialize} for method signature
        # @return [GraphQL::Schema::Field]
        def field(*args, **kwargs, &block)
          field_defn = field_class.from_options(*args, owner: self, **kwargs, &block)
          add_field(field_defn)
          field_defn
        end

        # @return [Hash<String => GraphQL::Schema::Field>] Fields on this object, keyed by name, including inherited fields
        def fields(context = GraphQL::Query::NullContext)
          warden = Warden.from_context(context)
          is_object = self.respond_to?(:kind) && self.kind.object?
          # Local overrides take precedence over inherited fields
          visible_fields = {}
          excluded_fields = []
          ancestors.each do |ancestor|
            next unless ancestor.respond_to?(:own_fields) &&
                        (is_object ? visible_interface_implementation?(ancestor, context, warden) : true)

            ancestor.own_fields.each do |field_name, fields_entry|
              next if visible_fields.key?(field_name) || excluded_fields.include?(field_name)

              if (f = Warden.visible_entry?(:visible_field?, fields_entry, context, warden))
                visible_fields[field_name] = f
              else
                excluded_fields << field_name
              end
            end
          end
          visible_fields
        end

        def get_field(field_name, context = GraphQL::Query::NullContext)
          warden = Warden.from_context(context)
          is_object = self.respond_to?(:kind) && self.kind.object?
          for ancestor in ancestors
            if ancestor.respond_to?(:own_fields) &&
                (is_object ? visible_interface_implementation?(ancestor, context, warden) : true) &&
                (f_entry = ancestor.own_fields[field_name]) &&
                (f = Warden.visible_entry?(:visible_field?, f_entry, context, warden))
              return f
            end
          end
          nil
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
          if method_conflict_warning && CONFLICT_FIELD_NAMES.include?(field_defn.resolver_method) && field_defn.original_name == field_defn.resolver_method && field_defn.original_name == field_defn.method_sym && field_defn.hash_key.nil? && field_defn.dig_keys.nil?
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

        private

        # If `type` is an interface, and `self` has a type membership for `type`, then make sure it's visible.
        def visible_interface_implementation?(type, context, warden)
          if type.respond_to?(:kind) && type.kind.interface?
            implements_this_interface = false
            implementation_is_visible = false
            interface_type_memberships.each do |tm|
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

        # @param [GraphQL::Schema::Field]
        # @return [String] A warning to give when this field definition might conflict with a built-in method
        def conflict_field_name_warning(field_defn)
          "#{self.graphql_name}'s `field :#{field_defn.original_name}` conflicts with a built-in method, use `resolver_method:` to pick a different resolver method for this field (for example, `resolver_method: :resolve_#{field_defn.resolver_method}` and `def resolve_#{field_defn.resolver_method}`). Or use `method_conflict_warning: false` to suppress this warning."
        end
      end
    end
  end
end
