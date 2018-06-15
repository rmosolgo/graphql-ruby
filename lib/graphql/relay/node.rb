# frozen_string_literal: true
module GraphQL
  module Relay
    # Helpers for working with Relay-specific Node objects.
    module Node
      # @return [GraphQL::Field] a field for finding objects by their global ID.
      def self.field(**kwargs, &block)
        # We have to define it fresh each time because
        # its name will be modified and its description
        # _may_ be modified.
        field = GraphQL::Field.define do
          type(GraphQL::Relay::Node.interface)
          description("Fetches an object given its ID.")
          argument(:id, types.ID.to_non_null_type, "ID of the object.")
          resolve(GraphQL::Relay::Node::FindNode)
          relay_node_field(true)
        end

        if kwargs.any? || block
          field = field.redefine(kwargs, &block)
        end

        field
      end

      def self.plural_field(**kwargs, &block)
        field = GraphQL::Field.define do
          type(!types[GraphQL::Relay::Node.interface])
          description("Fetches a list of objects given a list of IDs.")
          argument(:ids, types.ID.to_non_null_type.to_list_type.to_non_null_type, "IDs of the objects.")
          resolve(GraphQL::Relay::Node::FindNodes)
          relay_nodes_field(true)
        end

        if kwargs.any? || block
          field = field.redefine(kwargs, &block)
        end

        field
      end

      # @return [GraphQL::InterfaceType] The interface which all Relay types must implement
      def self.interface
        @interface ||= GraphQL::Types::Relay::Node.graphql_definition
      end

      # A field resolve for finding objects by IDs
      module FindNodes
        def self.call(obj, args, ctx)
          args[:ids].map { |id| ctx.query.schema.object_from_id(id, ctx) }
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
