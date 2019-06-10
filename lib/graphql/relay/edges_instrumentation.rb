# frozen_string_literal: true
module GraphQL
  module Relay
    module EdgesInstrumentation
      def self.instrument(type, field)
        if field.edges?
          edges_resolve = EdgesResolve.new(edge_class: field.edge_class, resolve: field.resolve_proc)
          edges_lazy_resolve = EdgesResolve.new(edge_class: field.edge_class, resolve: field.lazy_resolve_proc)

          field.redefine(
            resolve: edges_resolve,
            lazy_resolve: edges_lazy_resolve,
          )
        else
          field
        end
      end


      class EdgesResolve
        def initialize(edge_class:, resolve:)
          @edge_class = edge_class
          @resolve_proc = resolve
        end

        # A user's custom Connection may return a lazy object,
        # if so, handle it later.
        def call(obj, args, ctx)
          parent = ctx.object
          nodes = @resolve_proc.call(obj, args, ctx)
          if ctx.schema.lazy?(nodes)
            nodes
          else
            nodes.map { |item| item.is_a?(GraphQL::Pagination::Connection::Edge) ? item : @edge_class.new(item, parent) }
          end
        end
      end
    end
  end
end
