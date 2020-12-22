# frozen_string_literal: true
module GraphQL
  module Types
    module Relay
      # This can be used for implementing `Query.nodes(ids: ...)`,
      # or use it for inspiration for your own field definition.
      #
      # @example Adding this field directly
      #   add_field(GraphQL::Types::Relay::NodesField)
      #
      # @example Implementing a similar field in your own Query root
      #
      #   field :nodes, [GraphQL::Types::Relay::Node, null: true], null: false,
      #     description: Fetches a list of objects given a list of IDs." do
      #       argument :ids, [ID], required: true
      #     end
      #
      #   def nodes(ids:)
      #     ids.map do |id|
      #       context.schema.object_from_id(context, id)
      #     end
      #   end
      #
      NodesField = GraphQL::Schema::Field.new(**HasNodesField.field_options, &HasNodesField.field_block)
    end
  end
end
