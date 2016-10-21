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
      extend Gem::Deprecate

      # Just to encode data in the cursor, use something that won't conflict
      CURSOR_SEPARATOR = "---"

      # Map of collection class names -> connection_classes
      # eg {"Array" => ArrayConnection}
      CONNECTION_IMPLEMENTATIONS = {}

      class << self
        extend Gem::Deprecate

        # Find a connection implementation suitable for exposing `nodes`
        #
        # @param [Object] A collection of nodes (eg, Array, AR::Relation)
        # @return [subclass of BaseConnection] a connection Class for wrapping `nodes`
        def connection_for_nodes(nodes)
          # Check for class _names_ because classes can be redefined in Rails development
          ancestor_names = nodes.class.ancestors.map(&:name)
          implementation_class_name = ancestor_names.find do |ancestor_class_name|
            CONNECTION_IMPLEMENTATIONS.include? ancestor_class_name
          end

          if implementation_class_name.nil?
            raise("No connection implementation to wrap #{nodes.class} (#{nodes})")
          else
            CONNECTION_IMPLEMENTATIONS[implementation_class_name]
          end
        end

        # Add `connection_class` as the connection wrapper for `nodes_class`
        # eg, `RelationConnection` is the implementation for `AR::Relation`
        # @param [Class] A class representing a collection (eg, Array, AR::Relation)
        # @param [Class] A class implementing Connection methods
        def register_connection_implementation(nodes_class, connection_class)
          CONNECTION_IMPLEMENTATIONS[nodes_class.name] = connection_class
        end

        # @deprecated use {#connection_for_nodes} instead
        alias :connection_for_items :connection_for_nodes
        deprecate(:connection_for_items, :connection_for_nodes, 2016, 9)
      end

      attr_reader :nodes, :arguments, :max_page_size, :parent, :field

      # Make a connection, wrapping `nodes`
      # @param [Object] The collection of nodes
      # @param Query arguments
      # @param field [Object] The underlying field
      # @param max_page_size [Int] The maximum number of results to return
      # @param parent [Object] The object which this collection belongs to
      def initialize(nodes, arguments, field: nil, max_page_size: nil, parent: nil)
        @nodes = nodes
        @arguments = arguments
        @max_page_size = max_page_size
        @field = field
        @parent = parent
      end

      # @deprecated use {#nodes} instead
      alias :object :nodes
      deprecate(:object, :nodes, 2016, 9)

      # Provide easy access to provided arguments:
      METHODS_FROM_ARGUMENTS = [:first, :after, :last, :before]

      # @!method first
      #   The value passed as `first:`, if there was one
      # @!method after
      #   The value passed as `after:`, if there was one
      # @!method last
      #   The value passed as `last:`, if there was one
      # @!method before
      #   The value passed as `before:`, if there was one
      METHODS_FROM_ARGUMENTS.each do |arg_name|
        define_method(arg_name) do
          arguments[arg_name]
        end
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
        raise NotImplementedError, "must return a cursor for this object/connection pair"
      end

      private

      def paged_nodes
        raise NotImplementedError, "must return nodes for this connection after paging"
      end

      def sliced_nodes
        raise NotImplementedError, "must return  all nodes for this connection after chopping off first and last"
      end
    end
  end
end
