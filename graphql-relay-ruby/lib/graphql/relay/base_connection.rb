module GraphQL
  module Relay
    # Subclasses must implement:
    #   - {#cursor_from_node}, which returns an opaque cursor for the given item
    #   - {#sliced_nodes}, which slices by `before` & `after`
    #   - {#paged_nodes}, which applies `first` & `last` limits
    #
    # In a subclass, you have access to
    #   - {#object}, the object which the connection will wrap
    #   - {#first}, {#after}, {#last}, {#before} (arguments passed to the field)
    #   - {#max_page_size} (the specified maximum page size that can be returned from a connection)
    #
    class BaseConnection
      # Just to encode data in the cursor, use something that won't conflict
      CURSOR_SEPARATOR = "---"

      # Map of collection class names -> connection_classes
      # eg {"Array" => ArrayConnection}
      CONNECTION_IMPLEMENTATIONS = {}

      # Find a connection implementation suitable for exposing `items`
      #
      # @param [Object] A collection of items (eg, Array, AR::Relation)
      # @return [subclass of BaseConnection] a connection Class for wrapping `items`
      def self.connection_for_items(items)
        # We check class membership by comparing class names rather than
        # identity to prevent this from being broken by Rails autoloading.
        # Changes to the source file for ItemsClass in Rails apps cause it to be
        # reloaded as a new object, so if we were to use `is_a?` here, it would
        # no longer match any registered custom connection types.
        ancestor_names = items.class.ancestors.map(&:name)
        implementation = CONNECTION_IMPLEMENTATIONS.find do |items_class_name, connection_class|
          ancestor_names.include? items_class_name
        end
        if implementation.nil?
          raise("No connection implementation to wrap #{items.class} (#{items})")
        else
          implementation[1]
        end
      end

      # Add `connection_class` as the connection wrapper for `items_class`
      # eg, `RelationConnection` is the implementation for `AR::Relation`
      # @param [Class] A class representing a collection (eg, Array, AR::Relation)
      # @param [Class] A class implementing Connection methods
      def self.register_connection_implementation(items_class, connection_class)
        CONNECTION_IMPLEMENTATIONS[items_class.name] = connection_class
      end

      attr_reader :object, :arguments, :max_page_size, :parent

      # Make a connection, wrapping `object`
      # @param The collection of results
      # @param Query arguments
      # @param max_page_size [Int] The maximum number of results to return
      # @param parent [Object] The object which this collection belongs to
      def initialize(object, arguments, max_page_size: nil, parent: nil)
        @object = object
        @arguments = arguments
        @max_page_size = max_page_size
        @parent = parent
      end

      # Provide easy access to provided arguments:
      METHODS_FROM_ARGUMENTS = [:first, :after, :last, :before, :order]

      # @!method first
      #   The value passed as `first:`, if there was one
      # @!method after
      #   The value passed as `after:`, if there was one
      # @!method last
      #   The value passed as `last:`, if there was one
      # @!method before
      #   The value passed as `before:`, if there was one
      # @!method order
      #   The value passed as `order:`, if there was one
      METHODS_FROM_ARGUMENTS.each do |arg_name|
        define_method(arg_name) do
          arguments[arg_name]
        end
      end

      # These are the items to render for this connection,
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
        raise NotImplementedError, "must return items for this connection after paging"
      end

      def sliced_nodes
        raise NotImplementedError, "must return  all items for this connection after chopping off first and last"
      end
    end
  end
end
