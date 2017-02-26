# frozen_string_literal: true
module GraphQL
  class Field
    # Create resolve procs ahead of time based on a {GraphQL::Field}'s `name`, `property`, and `hash_key` configuration.
    module Resolve
      module_function

      # @param field [GraphQL::Field] A field that needs a resolve proc
      # @return [Proc] A resolver for this field, based on its config
      def create_proc(field)
        if field.property
          MethodResolve.new(field.property.to_sym)
        elsif !field.hash_key.nil?
          HashKeyResolve.new(field.hash_key)
        else
          NameResolve.new(field)
        end
      end

      # These only require `obj` as input
      class BuiltInResolve
        protected
        def method_with_arguments?(method, obj, args)
          args.to_h.keys.size > 0 &&
          obj.methods.include?(method.to_sym) &&
          obj.method(method).parameters.size > 0
        end
      end

      # Resolve the field by `public_send`ing `@method_name`
      class MethodResolve < BuiltInResolve
        def initialize(method_name)
          @method_name = method_name
        end

        def call(obj, args, ctx)
          if method_with_arguments?(@method_name, obj, args)
            obj.public_send(@method_name, args)
          else
            obj.public_send(@method_name)
          end
        end
      end

      # Resolve the field by looking up `@hash_key` with `#[]`
      class HashKeyResolve < BuiltInResolve
        def initialize(hash_key)
          @hash_key = hash_key
        end

        def call(obj, args, ctx)
          obj[@hash_key]
        end
      end

      # Call the field's name at query-time since
      # it might have changed
      class NameResolve < BuiltInResolve
        def initialize(field)
          @field = field
        end

        def call(obj, args, ctx)
          if method_with_arguments?(@field.name, obj, args)
            obj.public_send(@field.name, args)
          else
            obj.public_send(@field.name)
          end
        end
      end
    end
  end
end
