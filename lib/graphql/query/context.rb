module GraphQL
  class Query
    # Expose some query-specific info to field resolve functions.
    # It delegates `[]` to the hash that's passed to `GraphQL::Query#initialize`.
    class Context
      module Spawn
        def spawn(key:, irep_node:, parent_type:, field:, irep_nodes:)
          FieldResolutionContext.new(
            parent: self,
            key: key,
            irep_node: irep_node,
            parent_type: parent_type,
            field: field,
            irep_nodes: irep_nodes,
          )
        end
      end

      include Spawn

      attr_reader :execution_strategy
      # `strategy` is required by GraphQL::Batch
      alias_method :strategy, :execution_strategy

      def execution_strategy=(new_strategy)
        # GraphQL::Batch re-assigns this value but it was previously not used
        # (ExecutionContext#strategy was used instead)
        # now it _is_ used, but it breaks GraphQL::Batch tests
        @execution_strategy ||= new_strategy
      end

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

      def path
        []
      end

      class FieldResolutionContext
        extend Forwardable
        include Spawn

        attr_reader :irep_node, :field, :parent_type, :irep_nodes

        def initialize(parent:, key:, irep_node:, field:, parent_type:, irep_nodes:)
          @parent = parent
          @key = key
          @irep_node = irep_node
          @field = field
          @parent_type = parent_type
          @irep_nodes = irep_nodes
        end

        def_delegators :@parent, :[], :[]=, :query, :schema, :warden, :errors, :execution_strategy, :strategy

        # @return [GraphQL::Language::Nodes::Field] The AST node for the currently-executing field
        def ast_node
          @irep_node.ast_node
        end

        # Add error to current field resolution.
        # @param error [GraphQL::ExecutionError] an execution error
        # @return [void]
        def add_error(error)
          if !error.is_a?(ExecutionError)
            raise TypeError, "expected error to be a ExecutionError, but was #{error.class}"
          end

          error.ast_node ||= irep_node.ast_node
          error.path ||= path
          errors << error
          nil
        end

        def path
          @path ||= @parent.path + [@key]
        end
      end
    end
  end
end
