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
          field_defn = build_field(*args, **kwargs, &block)
          add_field(field_defn)
          nil
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

        # Register this field with the class, overriding a previous one if needed.
        # Also, add a parent method for resolving this field.
        # @param field_defn [GraphQL::Schema::Field]
        # @return [void]
        def add_field(field_defn)
          own_fields[field_defn.name] = field_defn
          if defined?(self::DefaultResolve)
            field_key = field_defn.name.inspect
            self::DefaultResolve.module_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{field_defn.method_sym}(**args)
                field_inst = self.class.fields[#{field_key}] || raise(%|Failed to find field #{field_key} for \#{self.class} among \#{self.class.fields.keys}|)
                field_inst.resolve_field_method(self, args, context)
              end
            RUBY
          end
          nil
        end

        # @return [Class] The class to initialize when adding fields to this kind of schema member
        def field_class(new_field_class = nil)
          if new_field_class
            @field_class = new_field_class
          elsif @field_class
            @field_class
          elsif self.is_a?(Class)
            superclass.respond_to?(:field_class) ? superclass.field_class : GraphQL::Schema::Field
          else
            ancestor = ancestors[1..-1].find { |a| a.respond_to?(:field_class) && a.field_class }
            ancestor ? ancestor.field_class : GraphQL::Schema::Field
          end
        end

        def global_id_field(field_name)
          field field_name, "ID", null: false, resolve: GraphQL::Relay::GlobalIdResolve.new(type: self)
        end

        # @return [Array<GraphQL::Schema::Field>] Fields defined on this class _specifically_, not parent classes
        def own_fields
          @own_fields ||= {}
        end

        private

        # Initialize a field with this class's field class, but don't attach it.
        def build_field(*args, **kwargs, &block)
          kwargs[:owner] = self
          field_class.new(*args, **kwargs, &block)
        end
      end
    end
  end
end
