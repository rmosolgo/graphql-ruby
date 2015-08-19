module GraphQL
  module Relay
    class RelationConnection < BaseConnection
      def cursor_from_node(item)
        order_value = item.public_send(order_name)
        cursor_parts = [order, order_value]
        Base64.strict_encode64(cursor_parts.join(CURSOR_SEPARATOR))
      end

      def order
        @order ||= (super || "id")
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

          if order
            items = items.order(order_name => order_direction)
          end

          if after
            _o, order_value = slice_from_cursor(after)
            sort_query = order_direction == :asc ? "? > ?" : "? < ?"
            puts sort_query, order_name, order_value
            items = items.where(sort_query, order_name, order_value)
          end

          if before
            _o, order_value = slice_from_cursor(before)
            sort_query = order_direction == :asc ? "? < ?" : "? > ?"
            p [sort_query, order_name, order_value]
            items = items.where(sort_query, order_name, order_value)
          end

          items
        end
      end

      def slice_from_cursor(cursor)
        decoded = Base64.decode64(cursor)
        order, order_value = decoded.split(CURSOR_SEPARATOR)
      end

      # Remove possible direction marker:
      def order_name
        @order_name ||= order.sub(/^-/, '')
      end

      # Check for direction marker
      def order_direction
        @order_direction ||= order.start_with?("-") ? :desc : :asc
      end
    end
  end
end
