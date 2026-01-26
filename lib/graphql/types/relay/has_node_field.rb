# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      # Include this module to your root Query type to get a Relay-compliant `node(id: ID!): Node` field that uses the schema's `object_from_id` hook.
      module HasNodeField
        def self.included(child_class)
          child_class.field(**field_options, &field_block)
        end

        def get_relay_node(id:)
          context.schema.object_from_id(id, context)
        end

        class << self
          def field_options
            {
              name: "node",
              type: GraphQL::Types::Relay::Node,
              null: true,
              description: "Fetches an object given its ID.",
              relay_node_field: true,
              method: :get_relay_node
            }
          end

          def field_block
            Proc.new {
              argument :id, "ID!",
                description: "ID of the object."
            }
          end
        end
      end
    end
  end
end
