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
        schema_type = schema.introspection_system.schema_type
        schema_type.metadata[:type_class].authorized_new(schema, @context)
      end

      def __type(name:)
        # This will probably break with non-Interpreter runtime
        @context.warden.get_type(name)
      end
    end
  end
end
