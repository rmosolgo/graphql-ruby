# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      # Use this to implement Relay connections, or take it as inspiration
      # for Relay classes in your own app.
      #
      # You may wish to copy this code into your own base class,
      # so you can extend your own `BaseObject` instead of `GraphQL::Schema::Object`.
      #
      # @example Implementation a connection and edge
      #   # Given some object in your app ...
      #   class Types::Post < BaseObject
      #   end
      #
      #   # Make a couple of base classes:
      #   class Types::BaseEdge < GraphQL::Types::Relay::BaseEdge; end
      #   class Types::BaseConnection < GraphQL::Types::Relay::BaseConnection; end
      #
      #   # Then extend them for the object in your app
      #   class Types::PostEdge < Types::BaseEdge
      #     node_type(Types::Post)
      #   end
      #   class Types::PostConnection < Types::BaseConnection
      #     edge_type(Types::PostEdge)
      #   end
      #
      # @see Relay::BaseEdge for edge types
      class BaseConnection < Types::Relay::BaseObject
        extend Forwardable
        def_delegators :@object, :cursor_from_node, :parent

        class << self
          # @return [Class]
          attr_reader :node_type

          # @return [Class]
          attr_reader :edge_type

          # Configure this connection to return `edges` and `nodes` based on `edge_type_class`.
          #
          # This method will use the inputs to create:
          # - `edges` field
          # - `nodes` field
          # - description
          #
          # It's called when you subclass this base connection, trying to use the
          # class name to set defaults. You can call it again in the class definition
          # to override the default (or provide a value, if the default lookup failed).
          def edge_type(edge_type_class, edge_class: GraphQL::Relay::Edge, node_type: edge_type_class.node_type)
            # Set this connection's graphql name
            node_type_name = node_type.graphql_name

            @node_type = node_type
            @edge_type = edge_type_class

            field :edges, [edge_type_class, null: true],
              null: true,
              description: "A list of edges.",
              method: :edge_nodes,
              edge_class: edge_class

            field :nodes, [node_type, null: true],
              null: true,
              description: "A list of nodes."

            description("The connection type for #{node_type_name}.")
          end

          # Add the shortcut `nodes` field to this connection and its subclasses
          def nodes_field
            field :nodes, [@node_type, null: true], null: true
          end
        end

        field :page_info, GraphQL::Types::Relay::PageInfo, null: false, description: "Information to aid in pagination."

        # By default this calls through to the ConnectionWrapper's edge nodes method,
        # but sometimes you need to override it to support the `nodes` field
        def nodes
          @object.edge_nodes
        end
      end
    end
  end
end
