# frozen_string_literal: true
require "graphql/backtrace/inspect_result"
require "graphql/backtrace/table"
require "graphql/backtrace/traced_error"
module GraphQL
  # Wrap unhandled errors with {TracedError}.
  #
  # {TracedError} provides a GraphQL backtrace with arguments and return values.
  # The underlying error is available as {TracedError#cause}.
  #
  # WARNING: {.enable} is not threadsafe because {GraphQL::Tracing.install} is not threadsafe.
  #
  # @example toggling backtrace annotation
  #   # to enable:
  #   GraphQL::Backtrace.enable
  #   # later, to disable:
  #   GraphQL::Backtrace.disable
  #
  module Backtrace
    module_function
    # Turn on annotation
    def enable
      execution_context.clear
      GraphQL::Tracing.install(self)
      nil
    end

    # Turn off annotation
    def disable
      GraphQL::Tracing.uninstall(self)
      nil
    end

    # Implement the {GraphQL::Tracing} API.
    def trace(key, metadata)
      push_data = case key
      when "lex", "parse"
        # No context here, don't have a query yet
        nil
      when "execute_multiplex", "analyze_multiplex"
        metadata[:multiplex].queries
      when "validate", "analyze_query", "execute_query", "execute_query_lazy"
        metadata[:query] || metadata[:queries]
      when "execute_field", "execute_field_lazy"
        metadata[:context]
      else
        # Custom key, no backtrace data for this
        nil
      end

      if push_data
        if key == "execute_multiplex"
          execution_context.clear
          execution_context.push(push_data)
          begin
            yield
          rescue StandardError => err
            # This is an unhandled error from execution,
            # Re-raise it with a GraphQL trace.
            raise TracedError.new(err, execution_context.last)
          ensure
            execution_context.clear
          end
        else
          execution_context.push(push_data)
          res = yield
          execution_context.pop
          res
        end
      else
        yield
      end
    end

    # A stack of objects corresponding to the GraphQL context.
    # @return [Array<GraphQL::Query::Context, GraphQL::Query>]
    def execution_context
      Thread.current[:graphql_execution_context] ||= []
    end
  end
end
