# frozen_string_literal: true

module GraphQL
  module Pagination
    # A Connection wraps a list of items and provides cursor-based pagination over it.
    #
    # Connections were introduced by Facebook's `Relay` front-end framework, but
    # proved to be generally useful for GraphQL APIs. When in doubt, use connections
    # to serve lists (like Arrays, ActiveRecord::Relations) via GraphQL.
    class Connection
      class PaginationImplementationMissingError < GraphQL::Error
      end

      attr_reader :items, :context

      # @param items [Object] some unpaginated collection item, like an `Array` or `ActiveRecord::Relation`
      # @param context [Query::Context]
      # @param first [Integer, nil] The limit parameter from the client, if it provided one
      # @param after [String, nil] A cursor for pagination, if the client provided one
      # @param last [Integer, nil] Limit parameter from the client, if provided
      # @param before [String, nil] A cursor for pagination, if the client provided one.
      def initialize(items, context, first: nil, after: nil, last: nil, before: nil)
        @items = items
        @context = context
        @first = first
        @after = afte
        @last = last
        @before = before
      end

      # @return [Array<Edge>] {nodes}, but wrapped with Edge instances
      def edges
        @edges ||= nodes.map { |n| self.class::Edge.new(self, n) }
      end

      # @return [Array<Object>] A slice of {items}, constrained by {@first}/{@after}/{@last}/{@before}
      def nodes
        raise PaginationImplementationMissingError, "Implement #{self.class}#nodes to paginate `@items`"
      end

      # The connection object itself implements `PageInfo` fields
      def page_info
        self
      end

      # @return [Boolean] True if there are more items after this page
      def has_next_page
        raise PaginationImplementationMissingError, "Implement #{self.class}#has_next_page to return the next-page check"
      end

      # @return [Boolean] True if there were items before these items
      def has_previous_page
        raise PaginationImplementationMissingError, "Implement #{self.class}#has_previous_page to return the previous-page check"
      end

      # @return [String] The cursor of the first item in {nodes}
      def start_cursor
        cursor_for(nodes.first)
      end

      # @return [String] The cursor of the last item in {nodes}
      def end_cursor
        cursor_for(nodes.last)
      end

      # Return a cursor for this item.
      # @param item [Object] one of the passed in {items}, taken from {nodes}
      # @return [String]
      def cursor_for(item)
        raise PaginationImplementationMissingError, "Implement #{self.class}#cursor_for(item) to return the cursor for #{item.inspect}"
      end

      # A wrapper around paginated items. It includes a {cursor} for pagination
      # and could be extended with custom relationship-level data.
      class Edge
        def initialize(connection, item)
          @connection = connection
          @item = item
        end

        def cursor
          @connection.cursor_for(@item)
        end
      end
    end
  end
end
