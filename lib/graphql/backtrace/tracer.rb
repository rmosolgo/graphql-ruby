# frozen_string_literal: true
module GraphQL
  class Backtrace
    module Tracer
      module_function

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
          Thread.current[:last_graphql_backtrace_context] = push_data
        end

        if key == "execute_multiplex"
          begin
            yield
          rescue StandardError => err
            # This is an unhandled error from execution,
            # Re-raise it with a GraphQL trace.
            potential_context = Thread.current[:last_graphql_backtrace_context]

            if potential_context.is_a?(GraphQL::Query::Context) || potential_context.is_a?(GraphQL::Query::Context::FieldResolutionContext)
              raise TracedError.new(err, potential_context)
            else
              raise
            end
          ensure
            Thread.current[:last_graphql_backtrace_context] = nil
          end
        else
          yield
        end
      end
    end
  end
end
