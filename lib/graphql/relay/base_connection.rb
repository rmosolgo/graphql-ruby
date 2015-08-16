module GraphQL
  module Relay
    class ConnectionType < GraphQL::ObjectType
      defined_by_config :name, :fields, :interfaces
      attr_accessor :connection_class
    end

    class BaseConnection < GraphQL::ObjectType
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

      attr_reader :object

      def initialize(object, args)
        @object = object
        @args = args
      end

      [:first, :after, :last, :before].each do |arg_name|
        define_method(arg_name) do
          @args[arg_name]
        end
      end

      def edges
        @edges ||= paged_edges.map { |item| Edge.new(item, self) }
      end

      def page_info
        self
      end

      def has_next_page
        first && all_edges.count > first
      end

      def has_previous_page
        last && all_edges.count > last
      end

      def cursor_from_node(object)
        raise NotImplementedError, "must return a cursor for this object/connection pair"
      end

      private

      def paged_edges
        raise NotImplementedError, "must items for this connection after paging"
      end

      def all_edges
        raise NotImplementedError, "must all items for this connection"
      end
    end
  end
end
