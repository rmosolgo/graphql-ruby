module GraphQL
  class Schema
    # This middleware will stop resolving new fields after `max_seconds` have elapsed.
    # After the time has passed, any remaining fields will be `nil`, with errors added
    # to the `errors` key. Any already-resolved fields will be in the `data` key, so
    # you'll get a partial response.
    #
    # Note that this will stop a query _in between_ field resolutions, but
    # it doesn't interrupt long-running `resolve` functions. Be sure to use
    # timeout options for external connections. For more info, see
    # www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/
    #
    # @example Stop resolving fields after 2 seconds
    #   MySchema.middleware << GraphQL::Schema::TimeoutMiddleware.new(max_seconds: 2)
    #
    class TimeoutMiddleware
      # This key is used for storing timeout data in the {Query::Context} instance
      DEFAULT_CONTEXT_KEY = :__timeout_at__
      # @param max_seconds [Numeric] how many seconds the query should be allowed to resolve new fields
      # @param context_key [Symbol] what key should be used to read and write to the query context
      def initialize(max_seconds:, context_key: DEFAULT_CONTEXT_KEY)
        @max_seconds = max_seconds
        @context_key = context_key
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
      #
      # @example Notifying Bugsnag on a timeout
      #   class CustomTimeoutMiddleware < GraphQL::Schema::TimeoutMiddleware
      #     def on_timeout(parent_type, parent_object, field_defn, field_args, query_ctx)
      #       # Get the error from the default implementation
      #       timeout_error = super
      #       # Post to your bug tracker:
      #       Bugsnag.notify(timeout_error, {query_string: query_ctx.query.query_string})
      #       # Return the error so it can be added to the `errors` hash
      #       timeout_error
      #     end
      #   end
      #
      #   MySchema.middleware << CustomTimeoutMiddleware.new(max_seconds: 1.5)
      #
      # @return [GraphQL::Schema::TimeoutMiddleware::TimeoutError] An error whose message will be added to the `errors` key
      def on_timeout(parent_type, parent_object, field_definition, field_args, query_context)
        TimeoutError.new(parent_type, field_definition)
      end
    end

    class TimeoutError < GraphQL::ExecutionError
      def initialize(parent_type, field_defn)
        super("Timeout on #{parent_type.name}.#{field_defn.name}")
      end
    end
  end
end
