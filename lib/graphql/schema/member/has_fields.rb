# frozen_string_literal: true
module GraphQL
  class Schema
    class Member
      # Shared code for Object and Interface
      module HasFields
        class << self
          # When this module is added to a class,
          # add a place for that class's default behaviors
          def self.extended(child_class)
            add_default_resolve_module(child_class)
            super
          end

          # Create a module which will have instance methods for implementing fields.
          # These will be `super` methods for fields in interfaces, objects and mutations.
          # Use an instance variable on the class instead of a constant
          # so that module namespaces won't be an issue. (If we used constants,
          # `child_class::DefaultResolve` might find a constant from an included module.)
          def add_default_resolve_module(child_class)
            if child_class.instance_variable_get(:@_default_resolve)
              # This can happen when an object implements an interface,
              # since that interface has the `included` hook above.
              return
            end

            default_resolve_module = Module.new
            child_class.instance_variable_set(:@_default_resolve, default_resolve_module)
            child_class.include(default_resolve_module)
          end
        end

        # When this is included into interfaces,
        # add a place for default field behaviors
        def included(child_class)
          HasFields.add_default_resolve_module(child_class)
          # Also, prepare a place for default field implementations
          super
        end

        # When a subclass of objects are created,
        # add a place for that subclass's default field behaviors
        def inherited(child_class)
          HasFields.add_default_resolve_module(child_class)
          super
        end

        # Add a field to this object or interface with the given definition
        # @see {GraphQL::Schema::Field#initialize} for method signature
        # @return [void]
        def field(*args, **kwargs, &block)
          field_defn = field_class.from_options(*args, owner: self, **kwargs, &block)
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
          if !method_defined?(field_defn.method_sym)
            # Only add the super method if there isn't one already.
            add_super_method(field_defn.name.inspect, field_defn.method_sym)
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
        # Find the magic module for holding super methods,
        # and add a field named `method_name` for implementing the field
        # called `field_name`.
        # It will be the `super` method if the method is overwritten in the class definition.
        def add_super_method(field_key, method_name)
          default_resolve_module = @_default_resolve
          if default_resolve_module.nil?
            # This should have been set up in one of the inherited or included hooks above,
            # if it wasn't, it's because those hooks weren't called because `super` wasn't present.
            raise <<-ERR
Uh oh! #{self} doesn't have a default resolve module. This probably means that an `inherited` hook didn't call super.
Check `inherited` on #{self}'s superclasses.
ERR
          end
          default_resolve_module.module_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{method_name}(**args)
              field_inst = self.class.fields[#{field_key}] || raise(%|Failed to find field #{field_key} for \#{self.class} among \#{self.class.fields.keys}|)
              field_inst.resolve_field_method(self, args, context)
            end
          RUBY
        end
      end
    end
  end
end
