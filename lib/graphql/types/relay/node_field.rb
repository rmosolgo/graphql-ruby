# frozen_string_literal: true
module GraphQL
  module Types
    module Relay
      # This can be used for implementing `Query.node(id: ...)`,
      # or use it for inspiration for your own field definition.
      NodeField = GraphQL::Schema::Field.new(
        name: "node",
        owner: nil,
        type: GraphQL::Types::Relay::Node,
        null: true,
        description: "Fetches an object given its ID.",
        relay_node_field: true,
      ) do
        argument :id, "ID!", required: true,
          description: "ID of the object."

        def resolve(obj, args, ctx)
          ctx.schema.object_from_id(args[:id], ctx)
        end

        def resolve_field(obj, args, ctx)
          resolve(obj, args, ctx)
        end
      end
    end
  end
end
