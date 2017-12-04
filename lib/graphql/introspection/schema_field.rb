# frozen_string_literal: true
module GraphQL
  module Introspection
    SchemaField = GraphQL::Field.define do
      name("__schema")
      description("This GraphQL schema")
      type(GraphQL::Introspection::SchemaType.to_non_null_type)
      resolve ->(o, a, ctx) {
        # Apply wrapping manually since this field isn't wrapped by instrumentation
        GraphQL::Introspection::SchemaType.new(ctx.query.schema, ctx.query.context)
      }
    end
  end
end
