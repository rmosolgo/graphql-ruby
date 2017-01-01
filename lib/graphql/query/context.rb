# frozen_string_literal: true
module GraphQL
  class Query
    # Expose some query-specific info to field resolve functions.
    # It delegates `[]` to the hash that's passed to `GraphQL::Query#initialize`.
    class Context
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
        @path = []
      end

      # Lookup `key` from the hash passed to {Schema#execute} as `context:`
      def [](key)
        @values[key]
      end

      # @return [GraphQL::Schema::Warden]
      def warden
        @warden ||= @query.warden
      end

      # Reassign `key` to the hash passed to {Schema#execute} as `context:`
      def []=(key, value)
        @values[key] = value
      end

      def spawn(key:, selection:, parent_type:, field:)
        FieldResolutionContext.new(
          context: self,
          path: path + [key],
          selection: selection,
          parent_type: parent_type,
          field: field,
        )
      end

      class FieldResolutionContext
        extend Forwardable

        attr_reader :path, :selection, :field, :parent_type

        def initialize(context:, path:, selection:, field:, parent_type:)
          @context = context
          @path = path
          @selection = selection
          @field = field
          @parent_type = parent_type
        end

        def_delegators :@context, :[], :[]=, :spawn, :query, :schema, :warden, :errors, :execution_strategy, :strategy

        # @return [GraphQL::Language::Nodes::Field] The AST node for the currently-executing field
        def ast_node
          selection.irep_node.ast_node
        end

        # @return [GraphQL::InternalRepresentation::Node]
        def irep_node
          selection.irep_node
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

        def spawn(key:, selection:, parent_type:, field:)
          FieldResolutionContext.new(
            context: @context,
            path: path + [key],
            selection: selection,
            parent_type: parent_type,
            field: field,
          )
        end
      end
    end
  end
end
