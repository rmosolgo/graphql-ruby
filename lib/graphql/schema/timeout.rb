# frozen_string_literal: true

module GraphQL
  class Schema
    # This plugin will stop resolving new fields after `max_seconds` have elapsed.
    # After the time has passed, any remaining fields will be `nil`, with errors added
    # to the `errors` key. Any already-resolved fields will be in the `data` key, so
    # you'll get a partial response.
    #
    # You can subclass `GraphQL::Schema::Timeout` and override the `handle_timeout` method
    # to provide custom logic when a timeout error occurs.
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
    # @example Notifying Bugsnag and logging a timeout
    #   class MyTimeout < GraphQL::Schema::Timeout
    #     def handle_timeout(error, query)
    #        Rails.logger.warn("GraphQL Timeout: #{error.message}: #{query.query_string}")
    #        Bugsnag.notify(error, {query_string: query.query_string})
    #     end
    #   end
    #
    #   class MySchema < GraphQL::Schema
    #     use MyTimeout, max_seconds: 2
    #   end
    #
    class Timeout
      attr_reader :max_seconds

      def self.use(schema, **options)
        tracer = new(**options)
        schema.tracer(tracer)
      end

      # @param max_seconds [Numeric] how many seconds the query should be allowed to resolve new fields
      def initialize(max_seconds:)
        @max_seconds = max_seconds
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
              handle_timeout(error, query)
            end

            error
          else
            yield
          end
        else
          yield
        end
      end

      # Invoked when a query times out.
      # @param error [GraphQL::Schema::Timeout::TimeoutError]
      # @param query [GraphQL::Error]
      def handle_timeout(error, query)
        # override to do something interesting
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
