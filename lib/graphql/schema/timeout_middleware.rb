module GraphQL
  class Schema
    # This middleware will stop resolving new fields after `max_seconds` have elapsed.
    # After the time has passed, any remaining fields will be `nil`, with errors added
    # to the `errors` key. Any already-resolved fields will be in the `data` key, so
    # you'll get a partial response.
    #
    # You can provide a block which will be called with any timeout errors that occur.
    #
    # Note that this will stop a query _in between_ field resolutions, but
    # it doesn't interrupt long-running `resolve` functions. Be sure to use
    # timeout options for external connections. For more info, see
    # www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/
    #
    # @example Stop resolving fields after 2 seconds
    #   MySchema.middleware << GraphQL::Schema::TimeoutMiddleware.new(max_seconds: 2)
    #
    # @example Notifying Bugsnag on a timeout
    #   MySchema.middleware << GraphQL::Schema::TimeoutMiddleware(max_seconds: 1.5) do |timeout_error, query|
    #    Bugsnag.notify(timeout_error, {query_string: query_ctx.query.query_string})
    #   end
    #
    class TimeoutMiddleware
      # This key is used for storing timeout data in the {Query::Context} instance
      DEFAULT_CONTEXT_KEY = :__timeout_at__
      # @param max_seconds [Numeric] how many seconds the query should be allowed to resolve new fields
      # @param context_key [Symbol] what key should be used to read and write to the query context
      ### Ruby 1.9.3 unofficial support
      # def initialize(max_seconds:, context_key: DEFAULT_CONTEXT_KEY, &block)
      def initialize(options = {}, &block)
        max_seconds = options[:max_seconds]
        context_key = options.fetch(:context_key, DEFAULT_CONTEXT_KEY)

        @max_seconds = max_seconds
        @context_key = context_key
        @error_handler = block
      end

      def call(parent_type, parent_object, field_definition, field_args, query_context, next_middleware)
        timeout_at = query_context[@context_key] ||= Time.now + @max_seconds

        if timeout_at < Time.now
          on_timeout(parent_type, parent_object, field_definition, field_args, query_context)
        else
          next_middleware.call
        end
      end

      # This is called when a field _would_ be resolved, except that we're over the time limit.
      # @return [GraphQL::Schema::TimeoutMiddleware::TimeoutError] An error whose message will be added to the `errors` key
      def on_timeout(parent_type, parent_object, field_definition, field_args, query_context)
        err = GraphQL::Schema::TimeoutMiddleware::TimeoutError.new(parent_type, field_definition)
        if @error_handler
          @error_handler.call(err, query_context.query)
        end
        err
      end

      # This error is raised when a query exceeds `max_seconds`.
      # Since it's a child of {GraphQL::ExecutionError},
      # its message will be added to the response's `errors` key.
      #
      # To raise an error that will stop query resolution, use a custom block
      # to take this error and raise a new one which _doesn't_ descend from {GraphQL::ExecutionError},
      # such as `RuntimeError`.
      class TimeoutError < GraphQL::ExecutionError
        def initialize(parent_type, field_defn)
          super("Timeout on #{parent_type.name}.#{field_defn.name}")
        end
      end
    end
  end
end
