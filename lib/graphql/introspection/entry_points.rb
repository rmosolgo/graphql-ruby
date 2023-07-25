# frozen_string_literal: true
module GraphQL
  module Introspection
    class EntryPoints < Introspection::BaseObject
      field :__schema, GraphQL::Schema::LateBoundType.new("__Schema"), "This GraphQL schema", null: false
      field :__type, GraphQL::Schema::LateBoundType.new("__Type"), "A type in the GraphQL system" do
        argument :name, String
      end

      def __schema
        # Apply wrapping manually since this field isn't wrapped by instrumentation
        schema = @context.query.schema
        schema_type = schema.introspection_system.types["__Schema"]
        schema_type.wrap(schema, @context)
      end

      def __type(name:)
        context.warden.reachable_type?(name) ? context.warden.get_type(name) : nil
      end
    end
  end
end
