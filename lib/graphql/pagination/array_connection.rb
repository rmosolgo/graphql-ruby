# frozen_string_literal: true
require "graphql/pagination/connection"

module GraphQL
  module Pagination
    class ArrayConnection < Pagination::Connection
      def nodes
        load_nodes
        @nodes
      end

      def has_previous_page
        load_nodes
        @has_previous_page
      end

      def has_next_page
        load_nodes
        @has_next_page
      end

      def cursor_for(item)
        index = cursor_index_for(item, items)
        encode((index + 1).to_s)
      end

      # @api private
      def cursor_for_position(_item, position)
        encode((@paged_nodes_offset + position + 1).to_s)
      end

      private

      def index_from_cursor(cursor)
        index = Integer(decode(cursor), 10, exception: false)
        if index.nil? || index <= 0
          raise GraphQL::ExecutionError, "Invalid cursor: #{cursor.inspect}"
        end
        [index, items.length + 1].min
      end

      # Populate all the pagination info _once_,
      # It doesn't do anything on subsequent calls.
      def load_nodes
        @nodes ||= begin
          sliced_nodes_offset = after ? index_from_cursor(after) : 0
          sliced_nodes = if before && after
            end_idx = index_from_cursor(before) - 2
            end_idx < 0 ? [] : items[sliced_nodes_offset..end_idx] || []
          elsif before
            end_idx = index_from_cursor(before) - 2
            end_idx < 0 ? [] : items[0..end_idx] || []
          elsif after
            items[sliced_nodes_offset..-1] || []
          else
            items
          end

          @has_previous_page = if last
            # There are items preceding the ones in this result
            sliced_nodes.count > last
          elsif after
            # We've paginated into the Array a bit, there are some behind us
            index_from_cursor(after) > 0
          else
            false
          end

          @has_next_page = if before
            # The original array is longer than the `before` index
            index_from_cursor(before) < items.length + 1
          elsif first
            # There are more items after these items
            sliced_nodes.count > first
          else
            false
          end

          limited_nodes = sliced_nodes
          @paged_nodes_offset = sliced_nodes_offset

          limited_nodes = limited_nodes.first(first) if first
          if last
            @paged_nodes_offset += [limited_nodes.length - last, 0].max
            limited_nodes = limited_nodes.last(last)
          end

          limited_nodes
        end
      end
    end
  end
end
