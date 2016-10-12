module GraphQL
  module Relay
    module ConnectionType
      # Create a connection which exposes edges of this type
      def self.create_type(wrapped_type, edge_type: nil, edge_class: nil, &block)
        edge_type ||= wrapped_type.edge_type
        edge_class ||= GraphQL::Relay::Edge
        connection_type_name = "#{wrapped_type.name}Connection"

        connection_type = ObjectType.define do
          name(connection_type_name)
          field :edges, types[edge_type] do
            description "A list of edges."
            resolve ->(obj, args, ctx) {
              obj.edge_nodes.map { |item| edge_class.new(item, obj) }
            }
          end
          field :pageInfo, !PageInfo, "Information to aid in pagination.", property: :page_info
          block && instance_eval(&block)
        end

        connection_type
      end
    end
  end
end
