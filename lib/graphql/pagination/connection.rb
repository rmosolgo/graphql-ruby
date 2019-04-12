# frozen_string_literal: true

module GraphQL
  module Pagination
    # A Connection wraps a list of items and provides cursor-based pagination over it.
    #
    # Connections were introduced by Facebook's `Relay` front-end framework, but
    # proved to be generally useful for GraphQL APIs. When in doubt, use connections
    # to serve lists (like Arrays, ActiveRecord::Relations) via GraphQL.
    #
    # Unlike the previous connection implementation, these default to bidirectional pagination.
    #
    # Pagination arguments and context may be provided at initialization or assigned later (see {Schema::Field::ConnectionExtension}).
    class Connection
      class PaginationImplementationMissingError < GraphQL::Error
      end

      # @return [Class] The class to use for wrapping items as `edges { ... }`. Defaults to `Connection::Edge`
      def self.edge_class
        self::Edge
      end

      # @return [Object] A list object, from the application. This is the unpaginated value passed into the connection.
      attr_reader :items

      # @return [GraphQL::Query::Context]
      attr_accessor :context

      attr_accessor :before, :after

      # @param items [Object] some unpaginated collection item, like an `Array` or `ActiveRecord::Relation`
      # @param context [Query::Context]
      # @param first [Integer, nil] The limit parameter from the client, if it provided one
      # @param after [String, nil] A cursor for pagination, if the client provided one
      # @param last [Integer, nil] Limit parameter from the client, if provided
      # @param before [String, nil] A cursor for pagination, if the client provided one.
      def initialize(items, context: nil, first: nil, after: nil, max_page_size: nil, last: nil, before: nil)
        @items = items
        @context = context
        @first = first
        @after = after
        @last = last
        @before = before
        @max_page_size = max_page_size
      end

      attr_writer :max_page_size
      def max_page_size
        @max_page_size ||= context.schema.default_max_page_size
      end

      attr_writer :first
      # @return [Integer, nil] a clamped `first` value. (The underlying instance variable doesn't have limits on it)
      def first
        limit_pagination_argument(@first, max_page_size)
      end

      attr_writer :last
      # @return [Integer, nil] a clamped `last` value. (The underlying instance variable doesn't have limits on it)
      def last
        limit_pagination_argument(@last, max_page_size)
      end

      # @return [Array<Edge>] {nodes}, but wrapped with Edge instances
      def edges
        @edges ||= nodes.map { |n| self.class.edge_class.new(n, self) }
      end

      # @return [Array<Object>] A slice of {items}, constrained by {@first}/{@after}/{@last}/{@before}
      def nodes
        raise PaginationImplementationMissingError, "Implement #{self.class}#nodes to paginate `@items`"
      end

      # A dynamic alias for compatibility with {Relay::BaseConnection}.
      # @deprecated use {#nodes} instead
      def edge_nodes
        nodes
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
        nodes.first && cursor_for(nodes.first)
      end

      # @return [String] The cursor of the last item in {nodes}
      def end_cursor
        nodes.last && cursor_for(nodes.last)
      end

      # Return a cursor for this item.
      # @param item [Object] one of the passed in {items}, taken from {nodes}
      # @return [String]
      def cursor_for(item)
        raise PaginationImplementationMissingError, "Implement #{self.class}#cursor_for(item) to return the cursor for #{item.inspect}"
      end

      private

      # @param argument [nil, Integer] `first` or `last`, as provided by the client
      # @param max_page_size [nil, Integer]
      # @return [nil, Integer] `nil` if the input was `nil`, otherwise a value between `0` and `max_page_size`
      def limit_pagination_argument(argument, max_page_size)
        if argument
          if argument < 0
            argument = 0
          elsif max_page_size && argument > max_page_size
            argument = max_page_size
          end
        end
        argument
      end

      def decode(cursor)
        context.schema.cursor_encoder.decode(cursor)
      end

      # A wrapper around paginated items. It includes a {cursor} for pagination
      # and could be extended with custom relationship-level data.
      class Edge
        def initialize(item, connection)
          @connection = connection
          @item = item
        end

        def node
          @item
        end

        def cursor
          @connection.cursor_for(@item)
        end
      end
    end
  end
end
