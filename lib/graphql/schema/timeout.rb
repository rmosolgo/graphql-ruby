# frozen_string_literal: true

module GraphQL
  class Schema
    # This plugin will stop resolving new fields after `max_seconds` have elapsed.
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
    #   class MySchema < GraphQL::Schema
    #     use GraphQL::Schema::Timeout, max_seconds: 2
    #   end
    #
    # @example Notifying Bugsnag on a timeout
    #   class MySchema < GraphQL::Schema
    #     use GraphQL::Schema::Timeout, max_seconds: 2, timeout_callback: ->(timeout_error, query) do
    #       Bugsnag.notify(timeout_error, {query_string: query.query_string})
    #     end
    #   end
    #
    class Timeout
      attr_reader :max_seconds, :timeout_callback

      def self.use(schema, **options)
        tracer = new(**options)
        schema.tracer(tracer)
      end

      # @param max_seconds [Numeric] how many seconds the query should be allowed to resolve new fields
      # @param timeout_callback [Proc] callback invoked when a query times out
      def initialize(max_seconds:, timeout_callback: nil)
        @max_seconds = max_seconds
        @timeout_callback = timeout_callback || Proc.new {}
      end

      def trace(key, data)
        case key
        when 'execute_multiplex'
          timeout_state = {
            timeout_at: Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) + max_seconds * 1000,
            timed_out: false
          }

          data.fetch(:multiplex).queries.each do |query|
            query.context.namespace(self.class)[:state] = timeout_state
          end

          yield
        when 'execute_field', 'execute_field_lazy'
          query = data[:context] ? data.fetch(:context).query : data.fetch(:query)
          timeout_state = query.context.namespace(self.class).fetch(:state)
          if Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) > timeout_state.fetch(:timeout_at)
            error = if data[:context]
              context = data.fetch(:context)
              GraphQL::Schema::Timeout::TimeoutError.new(context.parent_type, context.field)
            else
              field = data.fetch(:field)
              GraphQL::Schema::Timeout::TimeoutError.new(field.owner, field)
            end

            # Only invoke the timeout callback for the first timeout
            unless timeout_state[:timed_out]
              timeout_state[:timed_out] = true
              timeout_callback.call(error, query)
            end

            error
          else
            yield
          end
        else
          yield
        end
      end

      # This error is raised when a query exceeds `max_seconds`.
      # Since it's a child of {GraphQL::ExecutionError},
      # its message will be added to the response's `errors` key.
      #
      # To raise an error that will stop query resolution, use a custom block
      # to take this error and raise a new one which _doesn't_ descend from {GraphQL::ExecutionError},
      # such as `RuntimeError`.
      class TimeoutError < GraphQL::ExecutionError
        def initialize(parent_type, field)
          super("Timeout on #{parent_type.graphql_name}.#{field.graphql_name}")
        end
      end
    end
  end
end
