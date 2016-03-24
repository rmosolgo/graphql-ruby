module GraphQL
  module Relay
    class ArrayConnection < BaseConnection
      def cursor_from_node(item)
        idx = sliced_nodes.find_index(item)
        Base64.strict_encode64(idx.to_s)
      end

      private

      # apply first / last limit results
      def paged_nodes
        @paged_nodes = begin
          items = sliced_nodes
          limit = [first, last, max_page_size].compact.min
          first && items = items.first(limit)
          last && items.length > last && items.last(limit)
          items
        end
      end

      # Apply cursors to edges
      def sliced_nodes
        @sliced_nodes ||= begin
          items = object
          after && items = items[(1 + index_from_cursor(after))..-1]
          before && items = items[0..(index_from_cursor(before) - 1)]
          items
        end
      end

      def index_from_cursor(cursor)
        index = Base64.decode64(cursor)
        index.to_i
      end
    end
    BaseConnection.register_connection_implementation(Array, ArrayConnection)
  end
end
