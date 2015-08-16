module GraphQL
  module Relay
    class ArrayConnection < BaseConnection

      private

      # apply first / last to the slice of results
      def paged_edges
        @paged_edges = begin
          items = all_edges
          first && items = items.first(first)
          last && items.length > last && items.last(last)
          items
        end
      end

      # Handle before / after to get a slice of results
      def all_edges
        @object
      end
    end
  end
end
