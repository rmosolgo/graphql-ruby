# frozen_string_literal: true
module GraphQL
  module Introspection
    class EntryPoints < Introspection::BaseObject
      field :__schema, GraphQL::Schema::LateBoundType.new("__Schema"), "This GraphQL schema", null: false
      field :__type, GraphQL::Schema::LateBoundType.new("__Type"), "A type in the GraphQL system", null: true do
        argument :name, String, required: true
      end

      def __schema
        # Apply wrapping manually since this field isn't wrapped by instrumentation
        schema = @context.query.schema
        schema_type = schema.introspection_system.types["__Schema"]
        schema_type.type_class.authorized_new(schema, @context)
      end

      def __type(name:)
        return unless context.warden.reachable_type?(name)
        type = context.warden.get_type(name)

        if type && context.interpreter? && !type.is_a?(Module)
          type = type.type_class || raise("Invariant: interpreter requires class-based type for #{name}")
        end

        # The interpreter provides this wrapping, other execution doesnt, so support both.
        if type && !context.interpreter?
          # Apply wrapping manually since this field isn't wrapped by instrumentation
          type_type = context.schema.introspection_system.types["__Type"]
          type = type_type.type_class.authorized_new(type, context)
        end
        type
      end
    end
  end
end
