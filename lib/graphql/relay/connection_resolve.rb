# frozen_string_literal: true
module GraphQL
  module Relay
    class ConnectionResolve
      def initialize(field, underlying_resolve, max_page_size: nil)
        @field = field
        @underlying_resolve = underlying_resolve
        @max_page_size = max_page_size
      end

      def call(obj, args, ctx)
        nodes = @underlying_resolve.call(obj, args, ctx)
        if ctx.schema.lazy?(nodes)
          @field.prepare_lazy(nodes, args, ctx).then { |resolved_nodes|
            build_connection(resolved_nodes, args, obj, ctx)
          }
        else
          build_connection(nodes, args, obj, ctx)
        end
      end

      private

      def build_connection(nodes, args, parent, ctx)
        if nodes.is_a? GraphQL::ExecutionError
          ctx.add_error(nodes)
          nil
        else
          connection_class = GraphQL::Relay::BaseConnection.connection_for_nodes(nodes)
          connection_class.new(nodes, args, field: @field, max_page_size: @max_page_size, parent: parent, context: ctx)
        end
      end
    end
  end
end
