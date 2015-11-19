module GraphQL
  module Relay
    class RelationConnection < BaseConnection
      DEFAULT_ORDER = "id"

      def cursor_from_node(item)
        order_value = item.public_send(order_name)
        cursor_parts = [order, order_value]
        Base64.strict_encode64(cursor_parts.join(CURSOR_SEPARATOR))
      end

      def order
        @order ||= (super || DEFAULT_ORDER)
      end

      private

      # apply first / last limit results
      def paged_nodes
        @paged_nodes = begin
          items = sliced_nodes
          first && items = items.first(first)
          last && items.count > last && items = items.last(last)
          items
        end
      end

      # Apply cursors to edges
      def sliced_nodes
        @sliced_nodes ||= begin
          items = object

          if order
            items = items.order(items.table[order_name].public_send(order_direction))
          end

          if after
            _o, order_value = slice_from_cursor(after)
            direction_marker = order_direction == :asc ? ">" : "<"
            where_condition = create_order_condition(table_name, order_name, order_value, direction_marker)
            items = items.where(where_condition)
          end

          if before
            _o, order_value = slice_from_cursor(before)
            direction_marker = order_direction == :asc ? "<" : ">"
            where_condition = create_order_condition(table_name, order_name, order_value, direction_marker)
            items = items.where(where_condition)
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

      def table_name
        @table_name ||= object.table.table_name
      end

      def create_order_condition(table, column, value, direction_marker)
        table_name = ActiveRecord::Base.connection.quote_table_name(table)
        name = ActiveRecord::Base.connection.quote_column_name(column)
        ["#{table_name}.#{name} #{direction_marker} ?", value]
      end
    end


    if defined?(ActiveRecord)
      BaseConnection.register_connection_implementation(ActiveRecord::Relation, RelationConnection)
    end
  end
end
