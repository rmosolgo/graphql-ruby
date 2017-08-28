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
        @value = nil
      end

      attr_accessor :value

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

      def inspect
        "#<Query::Context ...>"
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

      # @return [Boolean] True if this selection has been nullified by a null child
      def invalid_null?
        @invalid_null
      end

      def delete(child)
        @value.delete(child.key)
      end

      def received_null_child
        @invalid_null = true
        @value = nil
      end

      def self.flatten(obj)
        case obj
        when Hash
          flattened = {}
          obj.each do |key, val|
            flattened[key] = flatten(val)
          end
          flattened
        when Array
          obj.map { |v| flatten(v) }
        when GraphQL::Query::Context, GraphQL::Query::Context::FieldResolutionContext
          if obj.invalid_null?
            nil
          else
            flatten(obj.value)
          end
        else
          obj
        end
      end

      class FieldResolutionContext
        extend GraphQL::Delegate

        attr_reader :selection, :field, :parent_type, :query, :schema, :parent, :key

        def initialize(context:, key:, selection:, parent:, field:, parent_type:)
          @context = context
          @key = key
          @parent = parent
          @selection = selection
          @field = field
          @parent_type = parent_type
          @type = field.type
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

        def inspect
          "#<GraphQL Context @ #{irep_node.owner_type.name}.#{field.name}>"
        end

        attr_reader :value

        # Set a new value for this field in the response.
        # It may be updated after resolving a {Lazy}.
        # If it is {Execute::PROPAGATE_NULL}, tell the owner to propagate null.
        # If it's {Execute::Execution::SKIP}, remove this field result from its parent
        # @param new_value [Any] The GraphQL-ready value
        def value=(new_value)
          case new_value
          when GraphQL::Execution::Execute::PROPAGATE_NULL, nil
            @invalid_null = true
            @value = nil
            if @type.kind.non_null?
              @parent.received_null_child
            end
          when GraphQL::Execution::Execute::SKIP
            @parent.delete(self)
          else
            @value = new_value
          end
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

        # @return [Boolean] True if this selection has been nullified by a null child
        def invalid_null?
          @invalid_null
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

        def delete(child)
          @value.delete(child.key)
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
