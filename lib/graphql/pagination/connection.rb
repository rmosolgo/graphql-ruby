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

      # Raw access to client-provided values. (`max_page_size` not applied to first or last.)
      attr_accessor :before_value, :after_value, :first_value, :last_value

      # @return [String, nil] the client-provided cursor
      def before
        @before_value
      end

      # @return [String, nil] the client-provided cursor
      def after
        @after_value
      end

      # @param items [Object] some unpaginated collection item, like an `Array` or `ActiveRecord::Relation`
      # @param context [Query::Context]
      # @param first [Integer, nil] The limit parameter from the client, if it provided one
      # @param after [String, nil] A cursor for pagination, if the client provided one
      # @param last [Integer, nil] Limit parameter from the client, if provided
      # @param before [String, nil] A cursor for pagination, if the client provided one.
      # @param max_page_size [Integer, nil] A configured value to cap the result size. Applied as `first` if neither first or last are given.
      def initialize(items, context: nil, first: nil, after: nil, max_page_size: nil, last: nil, before: nil)
        @items = items
        @context = context
        @first_value = first
        @after_value = after
        @last_value = last
        @before_value = before
        @max_page_size = max_page_size
      end

      attr_writer :max_page_size
      def max_page_size
        @max_page_size ||= context.schema.default_max_page_size
      end

      attr_writer :first
      # @return [Integer, nil]
      #   A clamped `first` value.
      #   (The underlying instance variable doesn't have limits on it.)
      #   If neither `first` nor `last` is given, but `max_page_size` is present, max_page_size is used for first.
      def first
        @first ||= begin
          capped = limit_pagination_argument(@first_value, max_page_size)
          if capped.nil? && last.nil?
            capped = max_page_size
          end
          capped
        end
      end

      attr_writer :last
      # @return [Integer, nil] A clamped `last` value. (The underlying instance variable doesn't have limits on it)
      def last
        @last ||= limit_pagination_argument(@last_value, max_page_size)
      end

      # @return [Array<Edge>] {nodes}, but wrapped with Edge instances
      def edges
        @edges ||= nodes.map { |n| self.class.edge_class.new(n, self) }
      end

      # @return [Array<Object>] A slice of {items}, constrained by {@first_value}/{@after_value}/{@last_value}/{@before_value}
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
