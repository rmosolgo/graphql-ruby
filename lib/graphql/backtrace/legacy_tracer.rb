# frozen_string_literal: true
module GraphQL
  class Backtrace
    module LegacyTracer
      module_function

      # Implement the {GraphQL::Tracing} API.
      def trace(key, metadata)
        case key
        when "lex", "parse"
          # No context here, don't have a query yet
          nil
        when "execute_multiplex", "analyze_multiplex"
          # No query context yet
          nil
        when "validate", "analyze_query", "execute_query", "execute_query_lazy"
          query = metadata[:query] || metadata[:queries].first
          push_data = query
          multiplex = query.multiplex
        when "execute_field", "execute_field_lazy"
          # The interpreter passes `query:`, legacy passes `context:`
          context = metadata[:context] || ((q = metadata[:query]) && q.context)
          push_data = context
          multiplex = context.query.multiplex
        else
          # Custom key, no backtrace data for this
          nil
        end

        if push_data
          multiplex.context[:last_graphql_backtrace_context] = push_data
        end

        if key == "execute_multiplex"
          begin
            yield
          rescue StandardError => err
            # This is an unhandled error from execution,
            # Re-raise it with a GraphQL trace.
            potential_context = metadata[:multiplex].context[:last_graphql_backtrace_context]

            if potential_context.is_a?(GraphQL::Query::Context) || potential_context.is_a?(GraphQL::Query::Context::FieldResolutionContext)
              raise TracedError.new(err, potential_context)
            else
              raise
            end
          ensure
            metadata[:multiplex].context.delete(:last_graphql_backtrace_context)
          end
        else
          yield
        end
      end
    end
  end
end
