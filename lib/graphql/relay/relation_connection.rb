module GraphQL
  module Relay
    # A connection implementation to expose SQL collection objects.
    # It works for:
    # - `ActiveRecord::Relation`
    # - `Sequel::Dataset`
    class RelationConnection < BaseConnection
      def cursor_from_node(item)
        offset = starting_offset + paged_nodes_array.index(item) + 1
        Base64.strict_encode64(offset.to_s)
      end

      def has_next_page
        exceeds_limit?(first)
      end

      # Used by `pageInfo`
      def has_previous_page
        exceeds_limit?(last)
      end

      private

      # apply first / last limit results
      def paged_nodes
        @paged_nodes ||= begin
          items = sliced_nodes
          items.limit(limit)
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

      # Returns true if the limit is specified
      # and there are more items that follow
      def exceeds_limit?(limit_value)
        !!(limit_value && sliced_nodes.limit(limit_value + 1).count > limit_value)
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
