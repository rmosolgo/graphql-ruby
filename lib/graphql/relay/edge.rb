module GraphQL
  module Relay
    # Mostly an internal concern.
    #
    # Wraps an object as a `node`, and exposes a connection-specific `cursor`.
    class Edge < GraphQL::ObjectType
      attr_reader :node, :parent, :connection
      def initialize(node, connection)
        @node = node
        @connection = connection
        @parent = parent
      end

      def cursor
        @cursor ||= connection.cursor_from_node(node)
      end

      def parent
        @parent ||= connection.parent
      end
    end
  end
end
