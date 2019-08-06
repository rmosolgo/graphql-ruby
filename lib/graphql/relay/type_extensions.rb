# frozen_string_literal: true
module GraphQL
  module Relay
    # Mixin for Relay-related methods in type objects
    # (used by BaseType and Schema::Member).
    module TypeExtensions
      # @return [GraphQL::ObjectType] The default connection type for this object type
      def connection_type
        @connection_type ||= define_connection
      end

      # Define a custom connection type for this object type
      # @return [GraphQL::ObjectType]
      def define_connection(**kwargs, &block)
        GraphQL::Relay::ConnectionType.create_type(self, **kwargs, &block)
      end

      # @return [GraphQL::ObjectType] The default edge type for this object type
      def edge_type
        @edge_type ||= define_edge
      end

      # Define a custom edge type for this object type
      # @return [GraphQL::ObjectType]
      def define_edge(**kwargs, &block)
        GraphQL::Relay::EdgeType.create_type(self, **kwargs, &block)
      end
    end
  end
end
