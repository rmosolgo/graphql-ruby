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
      def self.create_type(wrapped_type)
        edge_type = Edge.create_type(wrapped_type)

        connection_type = ConnectionType.define do
          name("#{wrapped_type.name}Connection")
          field :edges, types[edge_type]
          field :pageInfo, PageInfo, property: :page_info
        end

        connection_type.connection_class = self

        connection_type
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
