module GraphQL
  module Relay
    class ArrayConnection < BaseConnection
      # Just to encode data in the cursor, use something that won't conflict
      CURSOR_SEPARATOR = "---"

      def cursor_from_node(item)
        idx = sliced_nodes.find_index(item)
        cursor_parts = [(order || "none"), idx]
        Base64.strict_encode64(cursor_parts.join(CURSOR_SEPARATOR))
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
          if order
            # Remove possible direction marker:
            order_name = order.sub(/^-/, '')
            items = items.sort_by { |item| item.public_send(order_name) }
            order.start_with?("-") && items = items.reverse
          end
          after && items = items[(1 + index_from_cursor(after))..-1]
          before && items = items[0..(index_from_cursor(before) - 1)]
          items
        end
      end

      def index_from_cursor(cursor)
        decoded = Base64.decode64(cursor)
        order, index = decoded.split(CURSOR_SEPARATOR)
        index.to_i
      end
    end
    BaseConnection.register_connection_implementation(Array, ArrayConnection)
  end
end
