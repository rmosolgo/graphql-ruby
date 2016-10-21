module GraphQL
  class Query
    # Expose some query-specific info to field resolve functions.
    # It delegates `[]` to the hash that's passed to `GraphQL::Query#initialize`.
    class Context
      attr_accessor :execution_strategy

      # @return [GraphQL::Language::Nodes::Field] The AST node for the currently-executing field
      attr_accessor :ast_node

      # @return [GraphQL::InternalRepresentation::Node] The internal representation for this query node
      attr_accessor :irep_node

      # @return [Array<GraphQL::ExecutionError>] errors returned during execution
      attr_reader :errors

      # @return [GraphQL::Query] The query whose context this is
      attr_reader :query

      # @return [GraphQL::Schema]
      attr_reader :schema

      # Make a new context which delegates key lookup to `values`
      # @param query [GraphQL::Query] the query who owns this context
      # @param values [Hash] A hash of arbitrary values which will be accessible at query-time
      ### Ruby 1.9.3 unofficial support
      # def initialize(query:, values:)
      def initialize(options = {})
        query = options[:query]
        values = options[:values]

        @query = query
        @schema = query.schema
        @values = values || {}
        @errors = []
      end

      # Lookup `key` from the hash passed to {Schema#execute} as `context:`
      def [](key)
        @values[key]
      end

      # Reassign `key` to the hash passed to {Schema#execute} as `context:`
      def []=(key, value)
        @values[key] = value
      end
    end
  end
end
