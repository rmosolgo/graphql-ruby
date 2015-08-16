module GraphQL
  module Relay
    # Mostly an internal concern.
    #
    # Wraps an object as a `node`, and exposes a connection-specific `cursor`.
    class Edge < GraphQL::ObjectType
      attr_reader :node
      def initialize(node, connection)
        @node = node
        @connection = connection
      end

      def cursor
        @cursor ||= @connection.cursor_from_node(node)
      end

      def self.create_type(wrapped_type)
        GraphQL::ObjectType.define do
          name("#{wrapped_type.name}Edge")
          field :node, wrapped_type
          field :cursor, !types.String
        end
      end
    end
  end
end
