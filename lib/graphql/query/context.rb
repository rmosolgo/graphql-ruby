module GraphQL
  class Query
    # Expose some query-specific info to field resolve functions.
    # It delegates `[]` to the hash that's passed to `GraphQL::Query#initialize`.
    class Context
      attr_accessor :execution_strategy

      # @return [GraphQL::Language::Nodes::Field] The AST node for the currently-executing field
      def ast_node
        irep_node.ast_node
      end

      # @return [GraphQL::InternalRepresentation::Node] The internal representation for this query node
      attr_accessor :irep_node

      # @return [Array<GraphQL::ExecutionError>] errors returned during execution
      attr_reader :errors

      # @return [GraphQL::Query] The query whose context this is
      attr_reader :query

      # @return [GraphQL::Schema]
      attr_reader :schema

      # @return [GraphQL::Schema::Mask::Warden]
      attr_reader :warden

      # Make a new context which delegates key lookup to `values`
      # @param query [GraphQL::Query] the query who owns this context
      # @param values [Hash] A hash of arbitrary values which will be accessible at query-time
      def initialize(query:, values:)
        @query = query
        @schema = query.schema
        @values = values || {}
        @errors = []
        @warden = query.warden
      end

      # Lookup `key` from the hash passed to {Schema#execute} as `context:`
      def [](key)
        @values[key]
      end

      # Reassign `key` to the hash passed to {Schema#execute} as `context:`
      def []=(key, value)
        @values[key] = value
      end

      # Add error to current field resolution.
      # @param error [GraphQL::ExecutionError] an execution error
      # @return [void]
      def add_error(error)
        unless error.is_a?(ExecutionError)
          raise TypeError, "expected error to be a ExecutionError, but was #{error.class}"
        end

        error.ast_node = irep_node.ast_node unless error.ast_node
        error.path = irep_node.path unless error.path
        errors << error

        nil
      end
    end
  end
end
