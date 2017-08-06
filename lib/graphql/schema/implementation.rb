# frozen_string_literal: true
require "graphql/schema/implementation/apply_proxies"
require "graphql/schema/implementation/build_resolve"
require "graphql/schema/implementation/invalid_implementation_error"
require "graphql/schema/implementation/method_call_implementation"
require "graphql/schema/implementation/public_send_implementation"
require "graphql/schema/implementation/type_missing"

module GraphQL
  class Schema
    # This is a batteries-included approach to GraphQL schema development.
    #
    # - Define some classes that correspond to types
    # - Define some methods that correspond to fields on that type
    #   - Or don't; the default is still method-send
    # - Write `.graphql` files
    # - Build a schema
    #   - Glob the `.graphql` files
    #   - Instantiate an `Implementation`
    #   - Pass them to a schema builder
    # - Validate that the implementation suits the schema
    #
    # There's going to have to be a proxy wrapper layer
    # so that we can instantiate one graphql object per application object.
    #
    class Implementation
      # @param namespace [Module]
      def initialize(namespace: Object)
        @namespace = namespace
        @schema = nil
        @fields = nil
        @scalars = nil
      end

      def set_schema(schema)
        schema.metadata[:implementation] = self
        @schema = schema
        @fields = build_fields(schema)
        proxy_map = @fields[:proxies]
        schema.instrument(:field, ApplyProxies.new(proxy_map))
        # validate
      end

      def call(type, field, obj, args, ctx)
        callable = @fields
          .fetch(type.name)
          .fetch(field.name)

        callable.call(obj, args, ctx)
      end

      def resolve_type(type, obj, ctx)
      end

      def coerce_input(type, value, ctx)
      end

      def coerce_result(type, value,ctx)
      end

      private

      def build_fields(schema)
        # TODO this is a stupid hack, sharing the same hash like this
        map = {
          proxies: {}
        }

        # This is a fallback in case there's not a proxy class defined.
        # Application can define its own fallback, or we provide one
        default_impl = if @namespace.const_defined?(:TypeMissing)
          @namespace.const_get(:TypeMissing)
        else
          Implementation::TypeMissing
        end

        schema.types.each do |name, type|
          if type.kind.fields?
            # Introspection types can be defined in Introspection namespace
            # (constant names don't have `__`)
            impl_constant_name = name.sub(/^__/, "Introspection::")

            # Try to find a defined proxy class, otherwise use the fallback
            impl_class = if @namespace.const_defined?(impl_constant_name)
              @namespace.const_get(impl_constant_name)
            else
              default_impl
            end
            map[:proxies][name] = impl_class
            fields = map[name] = {}

            type.all_fields.each do |field|
              # Build a field from this proxy class
              fields[field.name] = BuildResolve.build(impl_class, field)
            end
          end
        end
        map
      end
    end
  end
end
