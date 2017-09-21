# frozen_string_literal: true
module GraphQL
  module Relay
    # Mostly an internal concern.
    #
    # Wraps an object as a `node`, and exposes a connection-specific `cursor`.
    class Edge
      attr_reader :node, :connection
      def initialize(node, connection)
        @node = node
        @connection = connection
      end

      def cursor
        @cursor ||= connection.cursor_from_node(node)
      end

      def parent
        @parent ||= connection.parent
      end

      def inspect
        "#<GraphQL::Relay::Edge (#{parent.inspect} => #{node.inspect})>"
      end
    end
  end
end
