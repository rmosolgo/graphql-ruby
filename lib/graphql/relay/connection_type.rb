# frozen_string_literal: true
module GraphQL
  module Relay
    module ConnectionType
      class << self
        attr_accessor :default_nodes_field
      end

      self.default_nodes_field = false

      # Create a connection which exposes edges of this type
      def self.create_type(wrapped_type, edge_type: nil, edge_class: nil, nodes_field: ConnectionType.default_nodes_field, &block)
        edge_class ||= GraphQL::Relay::Edge
        edge_type ||= wrapped_type.edge_type

        # Any call that would trigger `wrapped_type.ensure_defined`
        # must be inside this lazy block, otherwise we get weird
        # cyclical dependency errors :S
        ObjectType.define do
          name("#{wrapped_type.name}Connection")
          description("The connection type for #{wrapped_type.name}.")
          field :edges, types[edge_type] do
            description "A list of edges."
            resolve ->(obj, args, ctx) {
              obj.edge_nodes.map { |item| edge_class.new(item, obj) }
            }
          end
          if nodes_field
            field :nodes, types[wrapped_type] do
              description "A list of nodes."
              resolve ->(obj, args, ctx) {
                obj.edge_nodes
              }
            end
          end
          field :pageInfo, !PageInfo, "Information to aid in pagination.", property: :page_info
          block && instance_eval(&block)
        end
      end
    end
  end
end
