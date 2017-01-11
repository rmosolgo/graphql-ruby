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
        edge_type ||= wrapped_type.edge_type
        edge_class ||= GraphQL::Relay::Edge
        connection_type_name = "#{wrapped_type.name}Connection"
        connection_type_description = "The connection type for #{wrapped_type.name}."

        connection_type = ObjectType.define do
          name(connection_type_name)
          description(connection_type_description)
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

        connection_type
      end
    end
  end
end
