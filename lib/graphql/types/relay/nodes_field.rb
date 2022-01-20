# frozen_string_literal: true
module GraphQL
  module Types
    module Relay
      # Don't use this directly, instead, use one of these:
      #
      # @example Adding this field directly
      #   include GraphQL::Types::Relay::HasNodesField
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
      def self.const_missing(const_name)
        if const_name == :NodesField
          message = "NodesField is deprecated, use `include GraphQL::Types::Relay::HasNodesField` instead."
          message += "\n(referenced from #{caller(1, 1).first})"
          GraphQL::Deprecation.warn(message)

          DeprecatedNodesField
        elsif const_name == :NodeField
          message = "NodeField is deprecated, use `include GraphQL::Types::Relay::HasNodeField` instead."
          message += "\n(referenced from #{caller(1, 1).first})"
          GraphQL::Deprecation.warn(message)

          DeprecatedNodeField
        else
          super
        end
      end
      DeprecatedNodesField = GraphQL::Schema::Field.new(owner: nil, **HasNodesField.field_options, &HasNodesField.field_block)
    end
  end
end
