# frozen_string_literal: true
module GraphQL
  module Relay
    class ConnectionResolve
      def initialize(field, underlying_resolve)
        @field = field
        @underlying_resolve = underlying_resolve
        @max_page_size = field.connection_max_page_size
      end

      def call(obj, args, ctx)
        # in a lazy resolve hook, obj is the promise,
        # get the object that the promise was
        # originally derived from
        parent = ctx.object

        nodes = @underlying_resolve.call(obj, args, ctx)

        if nodes.nil? || ctx.schema.lazy?(nodes) || nodes.is_a?(GraphQL::Execution::Execute::Skip) || ctx.wrapped_connection
          nodes
        else
          ctx.wrapped_connection = true
          build_connection(nodes, args, parent, ctx)
        end
      end

      private

      def build_connection(nodes, args, parent, ctx)
        if nodes.is_a? GraphQL::ExecutionError
          ctx.add_error(nodes)
          nil
        else
          if parent.is_a?(GraphQL::Schema::Object)
            parent = parent.object
          end
          connection_class = GraphQL::Relay::BaseConnection.connection_for_nodes(nodes)
          connection_class.new(nodes, args, field: @field, max_page_size: @max_page_size, parent: parent, context: ctx)
        end
      end
    end
  end
end
