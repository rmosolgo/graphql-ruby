module GraphQL
  class Query
    # Expose some query-specific info to field resolve functions.
    # It delegates `[]` to the hash that's passed to `GraphQL::Query#initialize`.
    class Context
      attr_accessor :execution_strategy

      # @return [GraphQL::InternalRepresentation::Node] The internal representation for this query node
      attr_accessor :irep_node

      # @return [GraphQL::Language::Nodes::Field] The AST node for the currently-executing field
      def ast_node
        @irep_node.ast_node
      end

      # @return [Array<GraphQL::ExecutionError>] errors returned during execution
      attr_reader :errors

      # @return [GraphQL::Query] The query whose context this is
      attr_reader :query

      # @return [GraphQL::Schema]
      attr_reader :schema

      # @return [GraphQL::Schema::Mask::Warden]
      attr_reader :warden

      # @return [Array<String, Integer>] The current position in the result
      attr_reader :path

      # Make a new context which delegates key lookup to `values`
      # @param query [GraphQL::Query] the query who owns this context
      # @param values [Hash] A hash of arbitrary values which will be accessible at query-time
      def initialize(query:, values:)
        @query = query
        @schema = query.schema
        @values = values || {}
        @errors = []
        @warden = query.warden
        @path = []
      end

      # Lookup `key` from the hash passed to {Schema#execute} as `context:`
      def [](key)
        @values[key]
      end

      # Reassign `key` to the hash passed to {Schema#execute} as `context:`
      def []=(key, value)
        @values[key] = value
      end

      def spawn(path:, irep_node:)
        FieldResolutionContext.new(context: self, path: path, irep_node: irep_node)
      end

      class FieldResolutionContext
        extend Forwardable

        attr_reader :path, :irep_node

        def initialize(context:, path:, irep_node:)
          @context = context
          @path = path
          @irep_node = irep_node
        end

        def_delegators :@context, :[], :[]=, :spawn, :query, :schema, :warden, :errors, :execution_strategy

        # @return [GraphQL::Language::Nodes::Field] The AST node for the currently-executing field
        def ast_node
          @irep_node.ast_node
        end

        # Add error to current field resolution.
        # @param error [GraphQL::ExecutionError] an execution error
        # @return [void]
        def add_error(error)
          unless error.is_a?(ExecutionError)
            raise TypeError, "expected error to be a ExecutionError, but was #{error.class}"
          end

          error.ast_node ||= irep_node.ast_node
          error.path ||= path
          errors << error
          nil
        end
      end
    end
  end
end
