module GraphQL
  module Relay
    class ArrayConnection < BaseConnection
      def cursor_from_node(item)
        idx = sliced_nodes.find_index(item)
        "#{idx}"
      end

      private

      # apply first / last limit results
      def paged_nodes
        @paged_nodes = begin
          items = sliced_nodes
          first && items = items.first(first)
          last && items.length > last && items.last(last)
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
        cursor.to_i
      end
    end
  end
end
