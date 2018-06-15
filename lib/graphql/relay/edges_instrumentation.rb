# frozen_string_literal: true
module GraphQL
  module Relay
    module EdgesInstrumentation
      def self.instrument(type, field)
        if field.edges?
          edges_resolve = EdgesResolve.new(
            edge_class: field.edge_class,
            resolve: field.resolve_proc,
            lazy_resolve: field.lazy_resolve_proc,
          )

          field.redefine(
            resolve: edges_resolve.method(:resolve),
            lazy_resolve: edges_resolve.method(:lazy_resolve),
          )
        else
          field
        end
      end


      class EdgesResolve
        def initialize(edge_class:, resolve:, lazy_resolve:)
          @edge_class = edge_class
          @resolve_proc = resolve
          @lazy_resolve_proc = lazy_resolve
        end

        # A user's custom Connection may return a lazy object,
        # if so, handle it later.
        def resolve(obj, args, ctx)
          nodes = @resolve_proc.call(obj, args, ctx)
          if ctx.schema.lazy?(nodes)
            ConnectionResolve::LazyNodesWrapper.new(obj, nodes)
          else
            build_edges(nodes, obj)
          end
        end

        # If we get this far, unwrap the wrapper,
        # resolve the lazy object and make the edges as usual
        def lazy_resolve(obj, args, ctx)
          items = @lazy_resolve_proc.call(obj.lazy_object, args, ctx)
          build_edges(items, obj.parent)
        end

        private

        def build_edges(items, connection)
          items.map { |item| @edge_class.new(item, connection) }
        end
      end
    end
  end
end
