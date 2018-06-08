# frozen_string_literal: true
module GraphQL
  module Relay
    class ConnectionResolve
      def initialize(field, underlying_resolve)
        @field = field
        @underlying_resolve = underlying_resolve
        @max_page_size = field.connection_max_page_size
      end

      def call(parent, args, ctx)
        returned_nodes = @underlying_resolve.call(parent, args, ctx)

        ctx.schema.after_lazy(returned_nodes) do |nodes|
          if nodes.nil?
            nil
          elsif nodes.is_a?(GraphQL::Execution::Execute::Skip)
            nodes
          else
            build_connection(nodes, args, parent, ctx)
          end
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
