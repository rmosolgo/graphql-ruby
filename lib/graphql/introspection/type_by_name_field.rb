# frozen_string_literal: true
module GraphQL
  module Introspection
    TypeByNameField = GraphQL::Field.define do
      name("__type")
      description("A type in the GraphQL system")
      introspection true
      type(GraphQL::Schema::LateBoundType.new("__Type"))
      argument :name, !types.String
      resolve ->(o, args, ctx) {
        type = ctx.warden.get_type(args["name"])
        if type
          # Apply wrapping manually since this field isn't wrapped by instrumentation
          GraphQL::Introspection::TypeType.new(type, ctx)
        else
          nil
        end
      }
    end
  end
end
