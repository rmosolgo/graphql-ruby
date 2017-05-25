# frozen_string_literal: true
module GraphQL
  module Relay
    class ConnectionResolve
      def initialize(field, underlying_resolve, lazy:)
        @field = field
        @underlying_resolve = underlying_resolve
        @max_page_size = field.connection_max_page_size
        @lazy = lazy
      end

      def call(obj, args, ctx)
        if @lazy && obj.is_a?(LazyNodesWrapper)
          parent = obj.parent
          obj = obj.lazy_object
        else
          parent = obj
        end

        nodes = @underlying_resolve.call(obj, args, ctx)

        if nodes.nil?
          nil
        elsif ctx.schema.lazy?(nodes)
          if !@lazy
            LazyNodesWrapper.new(obj, nodes)
          else
            nodes
          end
        else
          build_connection(nodes, args, parent, ctx)
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

      # A container for the proper `parent` of connection nodes.
      # Without this wrapper, the lazy object _itself_ is passed into `build_connection`
      # and it becomes the parent, which is wrong.
      #
      # We can get away with it because we know that this instrumentation will be applied last.
      # That means its code after `underlying_resolve` will be _last_ on the way in.
      # And, its code before `underlying_resolve` will be _first_ during lazy resolution.
      # @api private
      LazyNodesWrapper = Struct.new(:parent, :lazy_object)
    end
  end
end
