module GraphQL
  module Relay
    class RelationConnection < BaseConnection
      def cursor_from_node(item)
        offset = starting_offset + paged_nodes_array.index(item) + 1
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

          final_limit = if limit || max_page_size
            [limit, max_page_size].compact.min
          end

          if final_limit
            items.limit(final_limit)
          else
            items
          end
        end
      end

      # Apply cursors to edges
      def sliced_nodes
        @sliced_nodes ||= begin
          items = object
          items.offset(starting_offset)
        end
      end

      def offset_from_cursor(cursor)
        Base64.decode64(cursor).to_i
      end

      def starting_offset
        @initial_offset ||= begin
          if before
            [previous_offset, 0].max
          else
            previous_offset
          end
        end
      end

      # Offset from the previous selection, if there was one
      # Otherwise, zero
      def previous_offset
        @previous_offset ||= if after
          offset_from_cursor(after)
        elsif before
          offset_from_cursor(before) - (last ? last : 0) - 1
        else
          0
        end
      end

      def limit
        @limit ||= if first
          first
        else
          if previous_offset <= 0
            previous_offset + (last ? last : 0)
          else
            last
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
