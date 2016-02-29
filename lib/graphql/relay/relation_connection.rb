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

      def has_next_page
        !!(first && sliced_nodes.limit(first + 1).count > first)
      end

      # Used by `pageInfo`
      def has_previous_page
        !!(last && sliced_nodes.limit(last + 1).count > last)
      end

      private

      # apply first / last limit results
      def paged_nodes
        @paged_nodes = begin
          items = sliced_nodes
          limit = [first, last, max_page_size].compact.min
          first && items = items.first(limit)
          last && items.count > last && items = items.last(limit)
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

      # When creating the where constraint, cast the value to correct column data type so
      # active record can send it in correct format to db
      def create_order_condition(table, column, value, direction_marker)
        table_name = ActiveRecord::Base.connection.quote_table_name(table)
        name = ActiveRecord::Base.connection.quote_column_name(column)
        if ActiveRecord::VERSION::MAJOR == 5
          casted_value = object.table.able_to_type_cast? ? object.table.type_cast_for_database(column, value) : value
        elsif ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR >= 2
          casted_value = object.table.engine.columns_hash[column].cast_type.type_cast_from_user(value)
        else
          casted_value = object.table.engine.columns_hash[column].type_cast(value)
        end
        ["#{table_name}.#{name} #{direction_marker} ?", casted_value]
      end
    end


    if defined?(ActiveRecord)
      BaseConnection.register_connection_implementation(ActiveRecord::Relation, RelationConnection)
    end
  end
end
