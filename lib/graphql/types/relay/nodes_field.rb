# frozen_string_literal: true
module GraphQL
  module Types
    module Relay
      # This can be used for implementing `Query.nodes(ids: ...)`,
      # or use it for inspiration for your own field definition.
      # @see GraphQL::Types::Relay::NodeField
      NodesField = GraphQL::Schema::Field.new(
        name: "nodes",
        owner: nil,
        type: [GraphQL::Types::Relay::Node, null: true],
        null: false,
        description: "Fetches a list of objects given a list of IDs.",
        relay_nodes_field: true,
      ) do
        argument :ids, "[ID!]!", required: true,
          description: "IDs of the objects."

        # TODO rename, make this public
        def resolve_field_2(obj, args, ctx)
          args[:ids].map { |id| ctx.schema.object_from_id(id, ctx) }
        end

        def resolve_field(obj, args, ctx)
          resolve_field_2(obj, args, ctx)
        end
      end
    end
  end
end
