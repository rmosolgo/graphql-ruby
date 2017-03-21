# frozen_string_literal: true
module GraphQL
  module Introspection
    SchemaField = GraphQL::Field.define do
      name("__schema")
      description("This GraphQL schema")
      type(!GraphQL::Introspection::SchemaType)
      resolve ->(o, a, ctx) { ctx.query.schema }
    end
  end
end
