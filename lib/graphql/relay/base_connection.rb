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
      # Map of collection class names -> connection_classes
      # eg `{"Array" => ArrayConnection}`
      CONNECTION_IMPLEMENTATIONS = {}

      class << self
        # Find a connection implementation suitable for exposing `nodes`
        #
        # @param nodes [Object] A collection of nodes (eg, Array, AR::Relation)
        # @return [subclass of BaseConnection] a connection Class for wrapping `nodes`
        def connection_for_nodes(nodes)
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

      attr_reader :nodes, :arguments, :max_page_size, :parent, :field

      # Make a connection, wrapping `nodes`
      # @param nodes [Object] The collection of nodes
      # @param arguments [GraphQL::Query::Arguments] Query arguments
      # @param field [GraphQL::Field] The underlying field
      # @param max_page_size [Int] The maximum number of results to return
      # @param parent [Object] The object which this collection belongs to
      # @param coder [Object] The object encodes and decodes a cursor
      def initialize(nodes, arguments, field: nil, max_page_size: nil, parent: nil, coder: nil, context: nil)
        @nodes = nodes
        @arguments = arguments
        @field = field
        @parent = parent
        @coder = coder.nil? ? GraphQL::Schema::Base64Encoder : coder
        @max_page_size = max_page_size
        @context = context
      end

      def encode(data)
        @coder.encode(data, nonce: true)
      end

      def decode(data)
        @coder.decode(data, nonce: true)
      end

      # @deprecated(reason: "Explicitly pass max_page_size and cursor")
      def context
        warn("Access to context is deprecated in BaseConection. Explicitly pass `max_page_size` and `cursor`")
        @context
      end

      # The value passed as `first:`, if there was one. Negative numbers become `0`.
      # @return [Integer, nil]
      def first
        @first ||= get_limited_arg(:first)
      end

      # The value passed as `after:`, if there was one
      # @return [String, nil]
      def after
        arguments[:after]
      end

      # The value passed as `last:`, if there was one. Negative numbers become `0`.
      # @return [Integer, nil]
      def last
        @last ||= get_limited_arg(:last)
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
        if start_node = paged_nodes.first
          cursor_from_node(start_node)
        else
          nil
        end
      end

      # Used by `pageInfo`
      def end_cursor
        if end_node = paged_nodes.last
          cursor_from_node(end_node)
        else
          nil
        end
      end

      # An opaque operation which returns a connection-specific cursor.
      def cursor_from_node(object)
        raise NotImplementedError, "must return a cursor for this object/connection pair"
      end

      private

      # Return a sanitized `arguments[arg_name]` (don't allow negatives)
      def get_limited_arg(arg_name)
        arg_value = arguments[arg_name]
        if arg_value.nil?
          arg_value
        elsif arg_value < 0
          0
        else
          arg_value
        end
      end

      def paged_nodes
        raise NotImplementedError, "must return nodes for this connection after paging"
      end

      def sliced_nodes
        raise NotImplementedError, "must return  all nodes for this connection after chopping off first and last"
      end
    end
  end
end
