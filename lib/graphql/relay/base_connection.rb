module GraphQL
  module Relay
    # Subclasses must implement:
    #   - {#cursor_from_node}, which returns an opaque cursor for the given item
    #   - {#sliced_edges}, which slices by `before` & `after`
    #   - {#paged_edges}, which applies `first` & `last` limits
    #
    # In a subclass, you have access to
    #   - {#object}, the object which the connection will wrap
    #   - {#first}, {#after}, {#last}, {#before} (arguments passed to the field)
    #
    class BaseConnection
      # Just to encode data in the cursor, use something that won't conflict
      CURSOR_SEPARATOR = "---"

      # Map of collection classes -> connection_classes
      # eg Array -> ArrayConnection
      CONNECTION_IMPLEMENTATIONS = {}

      # Create a connection which exposes edges of this type
      def self.create_type(wrapped_type, &block)
        edge_type = wrapped_type.edge_type

        connection_type = ObjectType.define do
          name("#{wrapped_type.name}Connection")
          field :edges, types[edge_type]
          field :pageInfo, PageInfo, property: :page_info
          block && instance_eval(&block)
        end

        connection_type
      end

      # @return [subclass of BaseConnection] a connection wrapping `items`
      def self.connection_for_items(items)
        implementation = CONNECTION_IMPLEMENTATIONS.find do |items_class, connection_class|
          items.is_a?(items_class)
        end
        if implementation.nil?
          raise("No connection implementation to wrap #{items.class} (#{items})")
        else
          implementation[1]
        end
      end

      # Add `connection_class` as the connection wrapper for `items_class`
      # eg, `RelationConnection` is the implementation for `AR::Relation`
      def self.register_connection_implementation(items_class, connection_class)
        CONNECTION_IMPLEMENTATIONS[items_class] = connection_class
      end

      attr_reader :object, :arguments

      def initialize(object, arguments)
        @object = object
        @arguments = arguments
      end

      # Provide easy access to provided arguments:
      METHODS_FROM_ARGUMENTS = [:first, :after, :last, :before, :order]

      METHODS_FROM_ARGUMENTS.each do |arg_name|
        define_method(arg_name) do
          arguments[arg_name]
        end
      end

      # Wrap nodes in {Edge}s so they expose cursors.
      def edges
        @edges ||= paged_nodes.map { |item| Edge.new(item, self) }
      end

      # Support the `pageInfo` field
      def page_info
        self
      end

      # Used by `pageInfo`
      def has_next_page
        first && sliced_nodes.count > first
      end

      # Used by `pageInfo`
      def has_previous_page
        last && sliced_nodes.count > last
      end

      # An opaque operation which returns a connection-specific cursor.
      def cursor_from_node(object)
        raise NotImplementedError, "must return a cursor for this object/connection pair"
      end

      private

      def paged_nodes
        raise NotImplementedError, "must items for this connection after paging"
      end

      def sliced_nodes
        raise NotImplementedError, "must all items for this connection after chopping off first and last"
      end
    end
  end
end
