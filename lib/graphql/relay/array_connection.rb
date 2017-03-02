# frozen_string_literal: true
module GraphQL
  module Relay
    class ArrayConnection < BaseConnection
      def cursor_from_node(item)
        idx = starting_offset + sliced_nodes.find_index(item) + 1
        encode(idx.to_s)
      end

      def has_next_page
        !!(first && sliced_nodes.count > limit)
      end

      def has_previous_page
        !!(last && starting_offset > 0)
      end

      private

      # apply first / last limit results
      def paged_nodes
        @paged_nodes ||= begin
          items = sliced_nodes

          if limit
            items.first(limit)
          else
            items
          end
        end
      end

      # Apply cursors to edges
      def sliced_nodes
        @sliced_nodes ||= nodes[starting_offset..-1] || []
      end

      def index_from_cursor(cursor)
        decode(cursor).to_i
      end

      def starting_offset
        @starting_offset = if before
          [previous_offset, 0].max
        elsif last
          [nodes.count - last, 0].max
        else
          previous_offset
        end
      end

      def previous_offset
        @previous_offset ||= if after
          index_from_cursor(after)
        elsif before
          prev_page_size = [max_page_size, last].compact.min || 0
          index_from_cursor(before) - prev_page_size - 1
        else
          0
        end
      end

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
    end
    BaseConnection.register_connection_implementation(Array, ArrayConnection)
  end
end
