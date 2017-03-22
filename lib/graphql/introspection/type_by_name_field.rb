# frozen_string_literal: true
module GraphQL
  module Introspection
    TypeByNameField = GraphQL::Field.define do
      name("__type")
      description("A type in the GraphQL system")
      type(GraphQL::Introspection::TypeType)
      argument :name, !types.String
      resolve ->(o, args, ctx) {
        ctx.warden.get_type(args["name"])
      }
    end
  end
end
