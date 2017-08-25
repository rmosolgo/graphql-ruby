# frozen_string_literal: true
module GraphQL
  class Query
    # Expose some query-specific info to field resolve functions.
    # It delegates `[]` to the hash that's passed to `GraphQL::Query#initialize`.
    class Context
      extend GraphQL::Delegate
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
        @provided_values = values || {}
        # Namespaced storage, where user-provided values are in `nil` namespace:
        @storage = Hash.new { |h, k| h[k] = {} }
        @storage[nil] = @provided_values
        @errors = []
        @path = []
      end

      def_delegators :@provided_values, :[], :[]=, :to_h, :key?, :fetch

      # @!method [](key)
      #   Lookup `key` from the hash passed to {Schema#execute} as `context:`

      # @!method []=(key, value)
      #   Reassign `key` to the hash passed to {Schema#execute} as `context:`

      # @return [GraphQL::Schema::Warden]
      def warden
        @warden ||= @query.warden
      end

      # Get an isolated hash for `ns`. Doesn't affect user-provided storage.
      # @param ns [Object] a usage-specific namespace identifier
      # @return [Hash] namespaced storage
      def namespace(ns)
        @storage[ns]
      end

      def spawn(key:, selection:, parent_type:, field:)
        FieldResolutionContext.new(
          context: self,
          parent: self,
          key: key,
          selection: selection,
          parent_type: parent_type,
          field: field,
        )
      end

      # Return this value to tell the runtime
      # to exclude this field from the response altogether
      def skip
        GraphQL::Execution::Execute::SKIP
      end

      # Add error at query-level.
      # @param error [GraphQL::ExecutionError] an execution error
      # @return [void]
      def add_error(error)
        if !error.is_a?(ExecutionError)
          raise TypeError, "expected error to be a ExecutionError, but was #{error.class}"
        end
        errors << error
        nil
      end

      class FieldResolutionContext
        extend GraphQL::Delegate

        attr_reader :selection, :field, :parent_type, :query, :schema

        def initialize(context:, key:, selection:, parent:, field:, parent_type:)
          @context = context
          @key = key
          @parent = parent
          @selection = selection
          @field = field
          @parent_type = parent_type
          # This is needed constantly, so set it ahead of time:
          @query = context.query
          @schema = context.schema
        end

        def path
          @path ||= @parent.path.dup << @key
        end

        def_delegators :@context,
          :[], :[]=, :key?, :fetch, :to_h, :namespace,
          :spawn, :schema, :warden, :errors,
          :execution_strategy, :strategy, :skip

        # @return [GraphQL::Language::Nodes::Field] The AST node for the currently-executing field
        def ast_node
          @selection.ast_node
        end

        # @return [GraphQL::InternalRepresentation::Node]
        def irep_node
          @selection
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
            parent: self,
            key: key,
            selection: selection,
            parent_type: parent_type,
            field: field,
          )
        end

        # Set a new value for this field in the response.
        # It may be updated after resolving a {Lazy}.
        # If it is {Execute::PROPAGATE_NULL}, tell the owner to propagate null.
        # If the value is a {SelectionResult}, make a link with it, and if it's already null,
        # propagate the null as needed.
        # If it's {Execute::Execution::SKIP}, remove this field result from its parent
        # @param new_value [Any] The GraphQL-ready value
        def value=(new_value)
          if new_value.is_a?(SelectionResult)
            if new_value.invalid_null?
              new_value = GraphQL::Execution::Execute::PROPAGATE_NULL
            else
              new_value.owner = self
            end
          end

          case new_value
          when GraphQL::Execution::Execute::PROPAGATE_NULL
            if @type.kind.non_null?
              @parent.propagate_null
            else
              @value = nil
            end
          when GraphQL::Execution::Execute::SKIP
            @parent.delete(self)
          else
            @value = new_value
          end
        end
      end
    end
  end
end
