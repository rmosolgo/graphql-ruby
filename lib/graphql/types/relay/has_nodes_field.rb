# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      # Include this module to your root Query type to get a Relay-style `nodes(id: ID!): [Node]` field that uses the schema's `object_from_id` hook.
      module HasNodesField
        def self.included(child_class)
          child_class.field(**field_options, &field_block)
        end

        def get_relay_nodes(ids:)
          ids.map { |id| context.schema.object_from_id(id, context) }
        end

        class << self
          def field_options
            {
              name: "nodes",
              type: [GraphQL::Types::Relay::Node, null: true],
              null: false,
              description: "Fetches a list of objects given a list of IDs.",
              relay_nodes_field: true,
              resolver_method: :get_relay_nodes
            }
          end

          def field_block
            Proc.new {
              argument :ids, "[ID!]!",
                description: "IDs of the objects."
            }
          end
        end
      end
    end
  end
end
