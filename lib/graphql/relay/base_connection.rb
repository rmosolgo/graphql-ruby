# frozen_string_literal: true
module GraphQL
  module Relay
    # Subclasses must implement:
    #   - {#cursor_from_node}, which returns an opaque cursor for the given item
    #   - {#sliced_nodes}, which slices by `before` & `after`
    #   - {#paged_nodes}, which applies `first` & `last` limits
    #
    # In a subclass, you have access to
    #   - {#nodes}, the collection which the connection will wrap
    #   - {#first}, {#after}, {#last}, {#before} (arguments passed to the field)
    #   - {#max_page_size} (the specified maximum page size that can be returned from a connection)
    #
    class BaseConnection
      # Just to encode data in the cursor, use something that won't conflict
      CURSOR_SEPARATOR = "---"

      # Map of collection class names -> connection_classes
      # eg `{"Array" => ArrayConnection}`
      CONNECTION_IMPLEMENTATIONS = {}

      class << self
        # Find a connection implementation suitable for exposing `nodes`
        #
        # @param nodes [Object] A collection of nodes (eg, Array, AR::Relation)
        # @return [subclass of BaseConnection] a connection Class for wrapping `nodes`
        def connection_for_nodes(nodes)
          # If it's a new-style connection object, it's already ready to go
          if nodes.is_a?(GraphQL::Pagination::Connection)
            return nodes
          end
          # Check for class _names_ because classes can be redefined in Rails development
          nodes.class.ancestors.each do |ancestor|
            conn_impl = CONNECTION_IMPLEMENTATIONS[ancestor.name]
            if conn_impl
              return conn_impl
            end
          end
          # Should have found a connection during the loop:
          raise("No connection implementation to wrap #{nodes.class} (#{nodes})")
        end

        # Add `connection_class` as the connection wrapper for `nodes_class`
        # eg, `RelationConnection` is the implementation for `AR::Relation`
        # @param nodes_class [Class] A class representing a collection (eg, Array, AR::Relation)
        # @param connection_class [Class] A class implementing Connection methods
        def register_connection_implementation(nodes_class, connection_class)
          CONNECTION_IMPLEMENTATIONS[nodes_class.name] = connection_class
        end
      end

      attr_reader :nodes, :arguments, :max_page_size, :parent, :field, :context

      # Make a connection, wrapping `nodes`
      # @param nodes [Object] The collection of nodes
      # @param arguments [GraphQL::Query::Arguments] Query arguments
      # @param field [GraphQL::Field] The underlying field
      # @param max_page_size [Int] The maximum number of results to return
      # @param parent [Object] The object which this collection belongs to
      # @param context [GraphQL::Query::Context] The context from the field being resolved
      def initialize(nodes, arguments, field: nil, max_page_size: nil, parent: nil, context: nil)
        GraphQL::Deprecation.warn "GraphQL::Relay::BaseConnection (used for #{self.class}) will be removed from GraphQL-Ruby 2.0, use GraphQL::Pagination::Connections instead: https://graphql-ruby.org/pagination/overview.html"

        deprecated_caller = caller(0, 10).find { |c| !c.include?("lib/graphql") }
        if deprecated_caller
          GraphQL::Deprecation.warn "  -> called from #{deprecated_caller}"
        end

        @context = context
        @nodes = nodes
        @arguments = arguments
        @field = field
        @parent = parent
        @encoder = context ? @context.schema.cursor_encoder : GraphQL::Schema::Base64Encoder
        @max_page_size = max_page_size.nil? && context ? @context.schema.default_max_page_size : max_page_size
      end

      def encode(data)
        @encoder.encode(data, nonce: true)
      end

      def decode(data)
        @encoder.decode(data, nonce: true)
      end

      # The value passed as `first:`, if there was one. Negative numbers become `0`.
      # @return [Integer, nil]
      def first
        @first ||= begin
          capped = limit_pagination_argument(arguments[:first], max_page_size)
          if capped.nil? && last.nil?
            capped = max_page_size
          end
          capped
        end
      end

      # The value passed as `after:`, if there was one
      # @return [String, nil]
      def after
        arguments[:after]
      end

      # The value passed as `last:`, if there was one. Negative numbers become `0`.
      # @return [Integer, nil]
      def last
        @last ||= limit_pagination_argument(arguments[:last], max_page_size)
      end

      # The value passed as `before:`, if there was one
      # @return [String, nil]
      def before
        arguments[:before]
      end

      # These are the nodes to render for this connection,
      # probably wrapped by {GraphQL::Relay::Edge}
      def edge_nodes
        @edge_nodes ||= paged_nodes
      end

      # Support the `pageInfo` field
      def page_info
        self
      end

      # Used by `pageInfo`
      def has_next_page
        !!(first && sliced_nodes.count > first)
      end

      # Used by `pageInfo`
      def has_previous_page
        !!(last && sliced_nodes.count > last)
      end

      # Used by `pageInfo`
      def start_cursor
        if start_node = (respond_to?(:paged_nodes_array, true) ? paged_nodes_array : paged_nodes).first
          return cursor_from_node(start_node)
        else
          return nil
        end
      end

      # Used by `pageInfo`
      def end_cursor
        if end_node = (respond_to?(:paged_nodes_array, true) ? paged_nodes_array : paged_nodes).last
          return cursor_from_node(end_node)
        else
          return nil
        end
      end

      # An opaque operation which returns a connection-specific cursor.
      def cursor_from_node(object)
        raise GraphQL::RequiredImplementationMissingError, "must return a cursor for this object/connection pair"
      end

      def inspect
        "#<GraphQL::Relay::Connection @parent=#{@parent.inspect} @arguments=#{@arguments.to_h.inspect}>"
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

      def paged_nodes
        raise GraphQL::RequiredImplementationMissingError, "must return nodes for this connection after paging"
      end

      def sliced_nodes
        raise GraphQL::RequiredImplementationMissingError, "must return  all nodes for this connection after chopping off first and last"
      end
    end
  end
end
