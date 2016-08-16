module GraphQL
  module Relay
    class ConnectionResolve
      def initialize(field, underlying_resolve, max_page_size: nil)
        @field = field
        @underlying_resolve = underlying_resolve
        @max_page_size = max_page_size
      end

      def call(obj, args, ctx)
        nodes = @underlying_resolve.call(obj, args, ctx)
        connection_class = GraphQL::Relay::BaseConnection.connection_for_nodes(nodes)
        connection_class.new(nodes, args, field: @field, max_page_size: @max_page_size, parent: obj)
      end
    end
  end
end
