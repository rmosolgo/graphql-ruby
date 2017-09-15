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
          execution_context = Thread.current[:graphql_execution_context] ||= []
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
    end
  end
end
