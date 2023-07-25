# frozen_string_literal: true
module GraphQL
  class Query
    # Expose some query-specific info to field resolve functions.
    # It delegates `[]` to the hash that's passed to `GraphQL::Query#initialize`.
    class Context
      module SharedMethods
        # Return this value to tell the runtime
        # to exclude this field from the response altogether
        def skip
          GraphQL::Execution::SKIP
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
      def initialize(query:, schema: query.schema, values:, object:)
        @query = query
        @schema = schema
        @provided_values = values || {}
        @object = object
        # Namespaced storage, where user-provided values are in `nil` namespace:
        @storage = Hash.new { |h, k| h[k] = {} }
        @storage[nil] = @provided_values
        @errors = []
        @path = []
        @value = nil
        @context = self # for SharedMethods TODO delete sharedmethods
        @scoped_context = ScopedContext.new(self)
      end

      class ScopedContext
        NO_PATH = GraphQL::EmptyObjects::EMPTY_ARRAY
        NO_CONTEXT = GraphQL::EmptyObjects::EMPTY_HASH

        def initialize(query_context)
          @query_context = query_context
          @scoped_contexts = nil
          @all_keys = nil
        end

        def merged_context
          if @scoped_contexts.nil?
            NO_CONTEXT
          else
            merged_ctx = {}
            each_present_path_ctx do |path_ctx|
              merged_ctx = path_ctx.merge(merged_ctx)
            end
            merged_ctx
          end
        end

        def merge!(hash)
          @all_keys ||= Set.new
          @all_keys.merge(hash.keys)
          ctx = @scoped_contexts ||= {}
          current_path.each do |path_part|
            ctx = ctx[path_part] ||= { parent: ctx }
          end
          this_scoped_ctx = ctx[:scoped_context] ||= {}
          this_scoped_ctx.merge!(hash)
        end

        def key?(key)
          if @all_keys && @all_keys.include?(key)
            each_present_path_ctx do |path_ctx|
              if path_ctx.key?(key)
                return true
              end
            end
          end
          false
        end

        def [](key)
          each_present_path_ctx do |path_ctx|
            if path_ctx.key?(key)
              return path_ctx[key]
            end
          end
          nil
        end

        def current_path
          @query_context.current_path || NO_PATH
        end

        def dig(key, *other_keys)
          each_present_path_ctx do |path_ctx|
            if path_ctx.key?(key)
              found_value = path_ctx[key]
              if other_keys.any?
                return found_value.dig(*other_keys)
              else
                return found_value
              end
            end
          end
          nil
        end

        private

        # Start at the current location,
        # but look up the tree for previously-assigned scoped values
        def each_present_path_ctx
          ctx = @scoped_contexts
          if ctx.nil?
            # no-op
          else
            current_path.each do |path_part|
              if ctx.key?(path_part)
                ctx = ctx[path_part]
              else
                break
              end
            end

            while ctx
              if (scoped_ctx = ctx[:scoped_context])
                yield(scoped_ctx)
              end
              ctx = ctx[:parent]
            end
          end
        end
      end

      # @return [Hash] A hash that will be added verbatim to the result hash, as `"extensions" => { ... }`
      def response_extensions
        namespace(:__query_result_extensions__)
      end

      def dataloader
        @dataloader ||= self[:dataloader] || (query.multiplex ? query.multiplex.dataloader : schema.dataloader_class.new)
      end

      # @api private
      attr_writer :interpreter

      # @api private
      attr_writer :value

      # @api private
      attr_reader :scoped_context

      def []=(key, value)
        @provided_values[key] = value
      end

      def_delegators :@query, :trace, :interpreter?

      RUNTIME_METADATA_KEYS = Set.new([:current_object, :current_arguments, :current_field, :current_path])
      # @!method []=(key, value)
      #   Reassign `key` to the hash passed to {Schema#execute} as `context:`

      # Lookup `key` from the hash passed to {Schema#execute} as `context:`
      def [](key)
        if @scoped_context.key?(key)
          @scoped_context[key]
        elsif @provided_values.key?(key)
          @provided_values[key]
        elsif RUNTIME_METADATA_KEYS.include?(key)
          if key == :current_path
            current_path
          else
            (current_runtime_state = Thread.current[:__graphql_runtime_info]) &&
              (query_runtime_state = current_runtime_state[@query]) &&
              (query_runtime_state.public_send(key))
          end
        else
          # not found
          nil
        end
      end

      def current_path
        current_runtime_state = Thread.current[:__graphql_runtime_info]
        query_runtime_state = current_runtime_state && current_runtime_state[@query]

        path = query_runtime_state &&
          (result = query_runtime_state.current_result) &&
          (result.path)
        if path && (rn = query_runtime_state.current_result_name)
          path = path.dup
          path.push(rn)
        end
        path
      end

      def delete(key)
        if @scoped_context.key?(key)
          @scoped_context.delete(key)
        else
          @provided_values.delete(key)
        end
      end

      UNSPECIFIED_FETCH_DEFAULT = Object.new

      def fetch(key, default = UNSPECIFIED_FETCH_DEFAULT)
        if RUNTIME_METADATA_KEYS.include?(key)
          (runtime = Thread.current[:__graphql_runtime_info]) &&
            (query_runtime_state = runtime[@query]) &&
            (query_runtime_state.public_send(key))
        elsif @scoped_context.key?(key)
          scoped_context[key]
        elsif @provided_values.key?(key)
          @provided_values[key]
        elsif default != UNSPECIFIED_FETCH_DEFAULT
          default
        elsif block_given?
          yield(self, key)
        else
          raise KeyError.new(key: key)
        end
      end

      def dig(key, *other_keys)
        if RUNTIME_METADATA_KEYS.include?(key)
          (current_runtime_state = Thread.current[:__graphql_runtime_info]) &&
            (query_runtime_state = current_runtime_state[@query]) &&
            (obj = query_runtime_state.public_send(key)) &&
            if other_keys.empty?
              obj
            else
              obj.dig(*other_keys)
            end
        elsif @scoped_context.key?(key)
          @scoped_context.dig(key, *other_keys)
        else
          @provided_values.dig(key, *other_keys)
        end
      end

      def to_h
        if (current_scoped_context = @scoped_context.merged_context)
          @provided_values.merge(current_scoped_context)
        else
          @provided_values
        end
      end

      alias :to_hash :to_h

      def key?(key)
        @scoped_context.key?(key) || @provided_values.key?(key)
      end

      # @return [GraphQL::Schema::Warden]
      def warden
        @warden ||= (@query && @query.warden)
      end

      # @api private
      attr_writer :warden

      # Get an isolated hash for `ns`. Doesn't affect user-provided storage.
      # @param ns [Object] a usage-specific namespace identifier
      # @return [Hash] namespaced storage
      def namespace(ns)
        if ns == :interpreter
          self
        else
          @storage[ns]
        end
      end

      # @return [Boolean] true if this namespace was accessed before
      def namespace?(ns)
        @storage.key?(ns)
      end

      def inspect
        "#<Query::Context ...>"
      end

      def scoped_merge!(hash)
        @scoped_context.merge!(hash)
      end

      def scoped_set!(key, value)
        scoped_merge!(key => value)
        nil
      end
    end
  end
end
