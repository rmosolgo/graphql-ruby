module GraphQL
  class Query
    # Expose some query-specific info to field resolve functions.
    # It delegates `[]` to the hash that's passed to `GraphQL::Query#initialize`.
    class Context
      attr_accessor :execution_strategy, :ast_node
      def initialize(values:)
        @values = values
      end

      def [](key)
        @values[key]
      end
    end
  end
end
