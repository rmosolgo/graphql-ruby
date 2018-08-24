# frozen_string_literal: true
module GraphQL
  module Relay
    class ArrayConnection < BaseConnection
      def cursor_from_node(item)
        idx = (after ? index_from_cursor(after) : 0) + sliced_nodes.find_index(item) + 1
        encode(idx.to_s)
      end

      def has_next_page
        if first
          # There are more items after these items
          sliced_nodes.count > first
        elsif GraphQL::Relay::ConnectionType.bidirectional_pagination && before
          # The original array is longer than the `before` index
          index_from_cursor(before) < nodes.length
        else
          false
        end
      end

      def has_previous_page
        if last
          # There are items preceding the ones in this result
          sliced_nodes.count > last
        elsif GraphQL::Relay::ConnectionType.bidirectional_pagination && after
          # We've paginated into the Array a bit, there are some behind us
          index_from_cursor(after) > 0
        else
          false
        end
      end

      private

      def first
        return @first if defined? @first

        @first = get_limited_arg(:first)
        @first = max_page_size if @first && max_page_size && @first > max_page_size
        @first
      end

      def last
        return @last if defined? @last

        @last = get_limited_arg(:last)
        @last = max_page_size if @last && max_page_size && @last > max_page_size
        @last
      end

      # apply first / last limit results
      def paged_nodes
        @paged_nodes ||= begin
          items = sliced_nodes

          items = items.first(first) if first
          items = items.last(last) if last
          items = items.first(max_page_size) if max_page_size && !first && !last

          items
        end
      end

      # Apply cursors to edges
      def sliced_nodes
        @sliced_nodes ||= if before && after
                            nodes[index_from_cursor(after)..index_from_cursor(before) - 1] || []
                          elsif before
                            nodes[0..index_from_cursor(before) - 2] || []
                          elsif after
                            nodes[index_from_cursor(after)..-1] || []
                          else
                            nodes
                          end
      end

      def index_from_cursor(cursor)
        decode(cursor).to_i
      end
    end

    BaseConnection.register_connection_implementation(Array, ArrayConnection)
  end
end
