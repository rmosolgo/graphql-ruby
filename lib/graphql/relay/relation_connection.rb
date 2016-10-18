module GraphQL
  module Relay
    # A connection implementation to expose SQL collection objects.
    # It works for:
    # - `ActiveRecord::Relation`
    # - `Sequel::Dataset`
    class RelationConnection < BaseConnection
      def cursor_from_node(item)
        item_index = paged_nodes_array.index(item)
        if item_index.nil?
          raise("Can't generate cursor, item not found in connection: #{item}")
        else
          offset = starting_offset + item_index + 1
          Base64.strict_encode64(offset.to_s)
        end
      end

      def has_next_page
        !!(first && sliced_nodes.limit(limit + 1).count > limit)
      end

      def has_previous_page
        !!(last && starting_offset > 0)
      end

      private

      # apply first / last limit results
      def paged_nodes
        @paged_nodes ||= sliced_nodes.limit(limit)
      end

      # Apply cursors to edges
      def sliced_nodes
        @sliced_nodes ||= nodes.offset(starting_offset)
      end

      def offset_from_cursor(cursor)
        Base64.decode64(cursor).to_i
      end

      def starting_offset
        @starting_offset ||= begin
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
          prev_page_size = [max_page_size, last].compact.min || 0
          offset_from_cursor(before) - prev_page_size - 1
        else
          0
        end
      end

      # Limit to apply to this query:
      # - find a value from the query
      # - don't exceed max_page_size
      # - otherwise, don't limit
      def limit
        @limit ||= begin
          limit_from_arguments = if first
            first
          else
            if previous_offset < 0
              previous_offset + (last ? last : 0)
            else
              last
            end
          end
          [limit_from_arguments, max_page_size].compact.min
        end
      end

      def paged_nodes_array
        @paged_nodes_array ||= paged_nodes.to_a
      end
    end

    if defined?(ActiveRecord::Relation)
      BaseConnection.register_connection_implementation(ActiveRecord::Relation, RelationConnection)
    end
    if defined?(Sequel::Dataset)
      BaseConnection.register_connection_implementation(Sequel::Dataset, RelationConnection)
    end
  end
end
