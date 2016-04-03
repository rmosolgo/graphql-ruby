module GraphQL
  module Relay
    class ArrayConnection < BaseConnection
      def cursor_from_node(item)
        idx = starting_offset + sliced_nodes.find_index(item) + 1
        Base64.strict_encode64(idx.to_s)
      end

      private

      # apply first / last limit results
      def paged_nodes
        @paged_nodes = begin
          items = sliced_nodes

          final_limit = if limit || max_page_size
            [limit, max_page_size].compact.min
          end

          if final_limit
            items.first(final_limit)
          else
            items
          end
        end
      end

      # Apply cursors to edges
      def sliced_nodes
        @sliced_nodes ||= begin
          items = object
          items[starting_offset..-1]
        end
      end

      def index_from_cursor(cursor)
        Base64.decode64(cursor).to_i
      end

      def starting_offset
        @starting_offset = if before
          [previous_offset, 0].max
        else
          previous_offset
        end
      end

      def previous_offset
        @initial_offset ||= if before
          index_from_cursor(before) - last - 1
        elsif after
          index_from_cursor(after)
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
    end
    BaseConnection.register_connection_implementation(Array, ArrayConnection)
  end
end
