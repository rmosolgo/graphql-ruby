# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module RelayShortcuts
        def edge_type_class(new_edge_type_class = nil)
          if new_edge_type_class
            @edge_type_class = new_edge_type_class
          else
            @edge_type_class || find_inherited_value(:edge_type_class, Types::Relay::BaseEdge)
          end
        end

        def connection_type_class(new_connection_type_class = nil)
          if new_connection_type_class
            @connection_type_class = new_connection_type_class
          else
            @connection_type_class || find_inherited_value(:connection_type_class, Types::Relay::BaseConnection)
          end
        end

        def edge_type
          @edge_type ||= begin
            edge_name = self.graphql_name + "Edge"
            node_type_class = self
            Class.new(edge_type_class) do
              graphql_name(edge_name)
              node_type(node_type_class)
            end
          end
        end

        def connection_type
          @connection_type ||= begin
            conn_name = self.graphql_name + "Connection"
            edge_type_class = self.edge_type
            Class.new(connection_type_class) do
              graphql_name(conn_name)
              edge_type(edge_type_class)
            end
          end
        end
      end
    end
  end
end
