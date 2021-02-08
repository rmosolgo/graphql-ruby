# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      # Shared code for Object and Interface
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
