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

      # @return [GraphQL::Query] The query whose context this is
      attr_reader :query

      # @return [GraphQL::Schema]
      attr_reader :schema

      # Make a new context which delegates key lookup to `values`
      # @param query [GraphQL::Query] the query who owns this context
      # @param values [Hash] A hash of arbitrary values which will be accessible at query-time
      def initialize(query:, values:)
        @query = query
        @schema = query.schema
        @values = values || {}
        @errors = []
      end

      # Lookup `key` from the hash passed to {Schema#execute} as `context`
      def [](key)
        @values[key]
      end

      def []=(key, value)
        @values[key] = value
      end
    end
  end
end
