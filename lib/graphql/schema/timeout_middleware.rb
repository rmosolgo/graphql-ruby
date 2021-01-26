# frozen_string_literal: true
require "delegate"

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
    # @api deprecated
    # @see Schema::Timeout
    class TimeoutMiddleware
      # @param max_seconds [Numeric] how many seconds the query should be allowed to resolve new fields
      def initialize(max_seconds:, context_key: nil, &block)
        @max_seconds = max_seconds
        if context_key
          GraphQL::Deprecation.warn("TimeoutMiddleware's `context_key` is ignored, timeout data is now stored in isolated storage")
        end
        @error_handler = block
      end

      def call(parent_type, parent_object, field_definition, field_args, query_context)
        ns = query_context.namespace(self.class)
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        timeout_at = ns[:timeout_at] ||= now + @max_seconds

        if timeout_at < now
          on_timeout(parent_type, parent_object, field_definition, field_args, query_context)
        else
          yield
        end
      end

      # This is called when a field _would_ be resolved, except that we're over the time limit.
      # @return [GraphQL::Schema::TimeoutMiddleware::TimeoutError] An error whose message will be added to the `errors` key
      def on_timeout(parent_type, parent_object, field_definition, field_args, field_context)
        err = GraphQL::Schema::TimeoutMiddleware::TimeoutError.new(parent_type, field_definition)
        if @error_handler
          query_proxy = TimeoutQueryProxy.new(field_context.query, field_context)
          @error_handler.call(err, query_proxy)
        end
        err
      end

      # This behaves like {GraphQL::Query} but {#context} returns
      # the _field-level_ context, not the query-level context.
      # This means you can reliably get the `irep_node` and `path`
      # from it after the fact.
      class TimeoutQueryProxy < SimpleDelegator
        def initialize(query, ctx)
          @context = ctx
          super(query)
        end

        attr_reader :context
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
