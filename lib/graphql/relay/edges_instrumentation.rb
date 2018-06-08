# frozen_string_literal: true
module GraphQL
  module Relay
    module EdgesInstrumentation
      def self.instrument(type, field)
        if field.edges?
          edges_resolve = EdgesResolve.new(
            edge_class: field.edge_class,
            resolve: field.resolve_proc,
          )

          field.redefine(
            resolve: edges_resolve.method(:resolve),
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
        def resolve(obj, args, ctx)
          nodes = @resolve_proc.call(obj, args, ctx)
          ctx.schema.after_lazy(nodes) do |items|
            items.map { |item| @edge_class.new(item, obj) }
          end
        end
      end
    end
  end
end
