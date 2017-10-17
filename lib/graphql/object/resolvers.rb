# frozen_string_literal: true
# test_via: ../object.rb

module GraphQL
  class Object
    module Resolvers
      # Grab the Resolve strategy which was assigned at boot
      class Metadata
        def call(obj, args, ctx)
          field_defn = ctx.field
          resolve_strategy = field_defn.metadata[:resolve_strategy]
          resolve_strategy.call(obj, args, ctx)
        end
      end

      # This is assigned at build-time. It should be overridden during boot.
      class Pending
        ERROR_MESSAGE = "Can't resolve %{name} because its resolve strategy is still pending." +
          " To resolve this error, call `Schema#boot` before running any queries."

        def call(obj, args, ctx)
          field_defn = ctx.field
          owner_type = ctx.irep_node.owner_type
          raise NotImplementedError, ERROR_MESSAGE % { name: "#{owner_type.name}.#{field_defn.name}" }
        end
      end

      class Booted
        def initialize(type_name:, field_name:, method_name:, object_class:)
          @type_name = type_name
          @field_name = field_name
          @method_name = method_name
          @object_class = object_class
        end

        def call(obj, args, ctx)
          raise NotImplementedError, "Subclasses should implement a resolve function"
        end
      end

      class MethodCall < Booted
        def initialize(*)
          super
          @has_args = has_args?
        end

        def call(obj, args, ctx)
          if @has_args
            kwargs = {}
            args.to_h.each { |k, v| kwargs[k.to_sym] = v }
            obj.public_send(@method_name, kwargs)
          else
            obj.public_send(@method_name)
          end
        end

        private

        def has_args?
          @object_class.instance_method(@method_name).arity != 0
        end
      end

      # Like calling a method on the object, except it unwraps the proxy
      # so that the method call goes to the underlying object
      class ModelMethod < MethodCall
        def call(obj, args, ctx)
          inner_obj = obj.object
          super(inner_obj, args, ctx)
        end

        private

        def has_args?
          @object_class.model.instance_method(@method_name).arity != 0
        end
      end

      # Like calling a method, except that the method might not be defined,
      # it might be handled w/ method_missing.
      # Designed for ActiveRecord::Base's column readers
      class ModelReader < ModelMethod
        private
        def has_args?
          false
        end
      end

      class InterfaceField < Booted
        def call(obj, args, ctx)
          # TODO can this lookup be cached?
          type = ctx.schema.types[@type_name]
          iface = type.interfaces.find { |i| i.fields[@field_name] }
          if iface.nil?
            raise Platform::Errors::Internal, "Failed to find interface to implement #{@type_name}.#{@field_name} (#{iface.inspect}, #{@field_name.inspect}, #{type.interfaces})"
          end
          field = ctx.schema.get_field(iface, @field_name)
          field.resolve(obj.object, args, ctx)
        end
      end
    end
  end
end
