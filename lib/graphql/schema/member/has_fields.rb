# frozen_string_literal: true
module GraphQL
  class Schema
    class Member
      # Shared code for Object and Interface
      module HasFields
        # Add a field to this object or interface with the given definition
        # @see {GraphQL::Schema::Field#initialize} for method signature
        # @return [void]
        def field(*args, **kwargs, &block)
          kwargs[:owner] = self
          field_defn = field_class.new(*args, **kwargs, &block)
          add_field(field_defn)
          nil
        end

        # @return [Hash<String => GraphQL::Schema::Field>] Fields on this object, keyed by name, including inherited fields
        def fields
          inherited_fields = (superclass.is_a?(HasFields) ? superclass.fields : {})
          # Local overrides take precedence over inherited fields
          inherited_fields.merge(own_fields)
        end

        # Register this field with the class, overriding a previous one if needed
        # @param field_defn [GraphQL::Schema::Field]
        # @return [void]
        def add_field(field_defn)
          own_fields[field_defn.name] = field_defn
          nil
        end

        # @return [Class] The class to initialize when adding fields to this kind of schema member
        def field_class(new_field_class = nil)
          if new_field_class
            @field_class = new_field_class
          else
            @field_class || (superclass.respond_to?(:field_class) ? superclass.field_class : GraphQL::Schema::Field)
          end
        end

        def global_id_field(field_name)
          field field_name, "ID", null: false, resolve: GraphQL::Relay::GlobalIdResolve.new(type: self)
        end

        private

        # @return [Array<GraphQL::Schema::Field>] Fields defined on this class _specifically_, not parent classes
        def own_fields
          @own_fields ||= {}
        end
      end
    end
  end
end
