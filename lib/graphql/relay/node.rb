# frozen_string_literal: true
module GraphQL
  module Relay
    # Helpers for working with Relay-specific Node objects.
    module Node
      # @return [GraphQL::Field] a field for finding objects by their global ID.
      def self.field
        # We have to define it fresh each time because
        # its name will be modified and its description
        # _may_ be modified.
        GraphQL::Field.define do
          type(GraphQL::Relay::Node.interface)
          description("Fetches an object given its ID.")
          argument(:id, !types.ID, "ID of the object.")
          resolve(GraphQL::Relay::Node::FindNode)
          relay_node_field(true)
        end
      end

      # @return [GraphQL::InterfaceType] The interface which all Relay types must implement
      def self.interface
        @interface ||= GraphQL::InterfaceType.define do
          name "Node"
          description "An object with an ID."
          field :id, !types.ID, "ID of the object."
          default_relay true
        end
      end

      # A field resolve for finding an object by ID
      module FindNode
        def self.call(obj, args, ctx)
          ctx.query.schema.object_from_id(args[:id], ctx )
        end
      end
    end
  end
end
