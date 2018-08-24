# frozen_string_literal: true
# test_via: ../execution/execute.rb
# test_via: ../execution/lazy.rb
module GraphQL
  class Query
    # Expose some query-specific info to field resolve functions.
    # It delegates `[]` to the hash that's passed to `GraphQL::Query#initialize`.
    class Context
      module SharedMethods
        # @return [Object] The target for field resultion
        attr_accessor :object

        # @return [Hash, Array, String, Integer, Float, Boolean, nil] The resolved value for this field
        attr_reader :value

        # @return [Boolean] were any fields of this selection skipped?
        attr_reader :skipped
        alias :skipped? :skipped

        # @api private
        attr_writer :skipped

        # Return this value to tell the runtime
        # to exclude this field from the response altogether
        def skip
          GraphQL::Execution::Execute::SKIP
        end

        # @return [Boolean] True if this selection has been nullified by a null child
        def invalid_null?
          @invalid_null
        end

        # Remove this child from the result value
        # (used for null propagation and skip)
        # @api private
        def delete(child_ctx)
          @value.delete(child_ctx.key)
        end

        # Create a child context to use for `key`
        # @param key [String, Integer] The key in the response (name or index)
        # @param irep_node [InternalRepresentation::Node] The node being evaluated
        # @api private
        def spawn_child(key:, irep_node:, object:)
          FieldResolutionContext.new(
            context: @context,
            parent: self,
            object: object,
            key: key,
            irep_node: irep_node,
          )
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

        # @example Print the GraphQL backtrace during field resolution
        #   puts ctx.backtrace
        #
        # @return [GraphQL::Backtrace] The backtrace for this point in query execution
        def backtrace
          GraphQL::Backtrace.new(self)
        end

        def execution_errors
          @execution_errors ||= ExecutionErrors.new(self)
        end
      end

      class ExecutionErrors
        def initialize(ctx)
          @context = ctx
        end

        def add(err_or_msg)
          err = case err_or_msg
                when String
                  GraphQL::ExecutionError.new(err_or_msg)
                when GraphQL::ExecutionError
                  err_or_msg
                else
                  raise ArgumentError, "expected String or GraphQL::ExecutionError, not #{err_or_msg.class} (#{err_or_msg.inspect})"
                end
          # This will assign ast_node and path
          @context.add_error(err)
        end

        alias :>> :add
        alias :push :add
      end

      include SharedMethods
      extend Forwardable

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
      def irep_node
        @irep_node ||= query.irep_selection
      end

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
      def initialize(query:, values:, object:)
        @query = query
        @schema = query.schema
        @provided_values = values || {}
        @object = object
        # Namespaced storage, where user-provided values are in `nil` namespace:
        @storage = Hash.new { |h, k| h[k] = {} }
        @storage[nil] = @provided_values
        @errors = []
        @path = []
        @value = nil
        @context = self # for SharedMethods
      end

      # @api private
      attr_writer :value

      def_delegators :@provided_values, :[], :[]=, :to_h, :key?, :fetch
      def_delegators :@query, :trace

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

      def inspect
        "#<Query::Context ...>"
      end

      # @api private
      def received_null_child
        @invalid_null = true
        @value = nil
      end

      class FieldResolutionContext
        include SharedMethods
        include Tracing::Traceable
        extend Forwardable

        attr_reader :irep_node, :field, :parent_type, :query, :schema, :parent, :key, :type
        alias :selection :irep_node

        def initialize(context:, key:, irep_node:, parent:, object:)
          @context = context
          @key = key
          @parent = parent
          @object = object
          @irep_node = irep_node
          @field = irep_node.definition
          @parent_type = irep_node.owner_type
          @type = field.type
          # This is needed constantly, so set it ahead of time:
          @query = context.query
          @schema = context.schema
          @tracers = @query.tracers
          # This hack flag is required by ConnectionResolve
          @wrapped_connection = false
          @wrapped_object = false
        end

        # @api private
        attr_accessor :wrapped_connection, :wrapped_object

        def path
          @path ||= @parent.path.dup << @key
        end

        def_delegators :@context,
          :[], :[]=, :key?, :fetch, :to_h, :namespace,
          :spawn, :warden, :errors,
          :execution_strategy, :strategy

        # @return [GraphQL::Language::Nodes::Field] The AST node for the currently-executing field
        def ast_node
          @irep_node.ast_node
        end

        # Add error to current field resolution.
        # @param error [GraphQL::ExecutionError] an execution error
        # @return [void]
        def add_error(error)
          super
          error.ast_node ||= irep_node.ast_node
          error.path ||= path
          nil
        end

        def inspect
          "#<GraphQL Context @ #{irep_node.owner_type.name}.#{field.name}>"
        end

        # Set a new value for this field in the response.
        # It may be updated after resolving a {Lazy}.
        # If it is {Execute::PROPAGATE_NULL}, tell the owner to propagate null.
        # If it's {Execute::Execution::SKIP}, remove this field result from its parent
        # @param new_value [Any] The GraphQL-ready value
        # @api private
        def value=(new_value)
          case new_value
          when GraphQL::Execution::Execute::PROPAGATE_NULL, nil
            @invalid_null = true
            @value = nil
            if @type.kind.non_null?
              @parent.received_null_child
            end
          when GraphQL::Execution::Execute::SKIP
            @parent.skipped = true
            @parent.delete(self)
          else
            @value = new_value
          end
        end

        protected

        def received_null_child
          case @value
          when Hash
            self.value = GraphQL::Execution::Execute::PROPAGATE_NULL
          when Array
            if list_of_non_null_items?(@type)
              self.value = GraphQL::Execution::Execute::PROPAGATE_NULL
            end
          when nil
            # TODO This is a hack
            # It was already nulled out but it's getting reassigned
          else
            raise "Unexpected value for received_null_child (#{self.value.class}): #{value}"
          end
        end

        private

        def list_of_non_null_items?(type)
          case type
          when GraphQL::NonNullType
            # Unwrap [T]!
            list_of_non_null_items?(type.of_type)
          when GraphQL::ListType
            type.of_type.is_a?(GraphQL::NonNullType)
          else
            raise "Unexpected list_of_non_null_items check: #{type}"
          end
        end
      end
    end
  end
end

GraphQL::Schema::Context = GraphQL::Query::Context
