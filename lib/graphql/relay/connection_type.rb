# frozen_string_literal: true
module GraphQL
  module Relay
    module ConnectionType
      class << self
        attr_accessor :default_nodes_field
      end

      self.default_nodes_field = false

      # Create a connection which exposes edges of this type
      def self.create_type(wrapped_type, edge_type: wrapped_type.edge_type, edge_class: GraphQL::Relay::Edge, nodes_field: ConnectionType.default_nodes_field, &block)
        custom_edge_class = edge_class

        # Any call that would trigger `wrapped_type.ensure_defined`
        # must be inside this lazy block, otherwise we get weird
        # cyclical dependency errors :S
        ObjectType.define do
          name("#{wrapped_type.name}Connection")
          description("The connection type for #{wrapped_type.name}.")
          field :edges, types[edge_type], "A list of edges.", edge_class: custom_edge_class, property: :edge_nodes

          if nodes_field
            field :nodes, types[wrapped_type],  "A list of nodes.", property: :edge_nodes
          end

          field :pageInfo, !PageInfo, "Information to aid in pagination.", property: :page_info
          block && instance_eval(&block)
        end
      end
    end
  end
end
