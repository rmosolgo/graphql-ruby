module GraphQL
  module Relay
    class ConnectionResolve
      def initialize(field_name, underlying_resolve, max_page_size: nil)
        @field_name = field_name
        @underlying_resolve = underlying_resolve
        @max_page_size = max_page_size
      end

      def call(obj, args, ctx)
        nodes = @underlying_resolve.call(obj, args, ctx)
        connection_class = GraphQL::Relay::BaseConnection.connection_for_nodes(nodes)
        connection_class.new(nodes, args, max_page_size: @max_page_size, field_name: @field_name, parent: obj)
      end
    end
  end
end
