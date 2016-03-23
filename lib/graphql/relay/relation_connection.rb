module GraphQL
  module Relay
    class RelationConnection < BaseConnection
      def cursor_from_node(item)
        offset = initial_offset + paged_nodes_array.index(item) + 1
        Base64.strict_encode64(offset.to_s)
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
        @paged_nodes ||= begin
          items = sliced_nodes
          limit = [first, last, max_page_size].compact.min
          items = items.limit(limit)
          items
        end
      end

      # Apply cursors to edges
      def sliced_nodes
        @sliced_nodes ||= begin
          items = object
          items = items.offset(initial_offset)
          items
        end
      end

      def offset_from_cursor(cursor)
        Base64.decode64(cursor).to_i
      end

      def initial_offset
        @initial_offset ||= begin
          if after
            # The initial offset is in the last cursor
            offset_from_cursor(after)
          elsif before
            # The initial offset
            prev_offset = offset_from_cursor(before)
            min_next_offset = prev_offset - last - 1
            next_offset = [min_next_offset, 0].max
            next_offset
          else
            0
          end
        end
      end

      def paged_nodes_array
        @paged_nodes_array ||= paged_nodes.to_a
      end
    end


    if defined?(ActiveRecord)
      BaseConnection.register_connection_implementation(ActiveRecord::Relation, RelationConnection)
    end
  end
end
