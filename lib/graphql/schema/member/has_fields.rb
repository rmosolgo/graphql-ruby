# frozen_string_literal: true
module GraphQL
  class Schema
    class Member
      # Shared code for Object and Interface
      module HasFields
        # Add a field to this object or interface with the given definition
        # @see {GraphQL::Schema::Field#initialize} for method signature
        # @return [void]
        def field(*args, &block)
          field_defn = field_class.new(*args, &block)
          add_field(field_defn)
          nil
        end

        # @return [Array<GraphQL::Schema::Field>] Fields on this object, including inherited fields
        def fields
          all_fields = own_fields
          inherited_fields = (superclass.is_a?(HasFields) ? superclass.fields : [])
          # Remove any inherited fields which were overridden on this class:
          inherited_fields.each do |inherited_f|
            if all_fields.none? {|f| f.name == inherited_f.name}
              all_fields << inherited_f
            end
          end
          all_fields
        end

        # Register this field with the class, overriding a previous one if needed
        # @param field_defn [GraphQL::Schema::Field]
        # @return [void]
        def add_field(field_defn)
          fields.reject! {|f| f.name == field_defn.name}
          own_fields << field_defn
          nil
        end

        # Override this method to customize fields in your schema.
        #
        # To customize fields on {GraphQL::Schema::Object} and {GraphQL::Schema::Interface},
        # - extend each of those classes, making a custom base class for your app
        # - extend {GraphQL::Schema::Field}, making a custom base class for your app
        # - override {.field_class} on your Object and Interface classes to return your new field class
        #
        # @return [Class] The class to initialize when adding fields to this kind of schema member
        def field_class
          self::Field
        end

        private

        # @return [Array<GraphQL::Schema::Field>] Fields defined on this class _specifically_, not parent classes
        def own_fields
          @own_fields ||= []
        end
      end
    end
  end
end
