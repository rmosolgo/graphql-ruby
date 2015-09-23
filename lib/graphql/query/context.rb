module GraphQL
  class Query
    # Expose some query-specific info to field resolve functions.
    # It delegates `[]` to the hash that's passed to `GraphQL::Query#initialize`.
    class Context
      attr_accessor :execution_strategy

      # The {GraphQL::Language::Nodes::Field} for the currently-executing field.
      # @return [GraphQL::Language::Nodes::Field]
      attr_accessor :ast_node

      # @return [Array<GraphQL::ExecutionError>] errors returned during execution
      attr_reader :errors

      # Make a new context which delegates key lookup to `values`
      # @param [Hash] A hash of arbitrary values which will be accessible at query-time
      def initialize(values:)
        @values = values
        @errors = []
      end

      # Lookup `key` from the hash passed to {Schema#execute} as `context`
      def [](key)
        @values[key]
      end
    end
  end
end
