# frozen_string_literal: true
module GraphQL
  module Introspection
    SchemaField = GraphQL::Field.define do
      name("__schema")
      description("This GraphQL schema")
      type(GraphQL::Schema::LateBoundType.new("__Schema").to_non_null_type)
      resolve ->(o, a, ctx) {
        # Apply wrapping manually since this field isn't wrapped by instrumentation
        schema = ctx.query.schema
        schema_type = schema.introspection_system.schema_type
        schema_type.metadata[:object_class].new(schema, ctx.query.context)
      }
    end
  end
end
