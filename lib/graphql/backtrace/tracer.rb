# frozen_string_literal: true
module GraphQL
  class Backtrace
    # TODO this is not fiber-friendly
    module Tracer
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
          push_key = []
          push_data = query
          multiplex = query.multiplex
        when "execute_field", "execute_field_lazy"
          query = metadata[:query] || raise(ArgumentError, "Add `legacy: true` to use GraphQL::Backtrace without the interpreter runtime.")
          multiplex = query.multiplex
          push_key = metadata[:path].reject { |i| i.is_a?(Integer) }
          parent_frame = multiplex.context[:graphql_backtrace_contexts][push_key[0..-2]]

          if parent_frame.is_a?(GraphQL::Query)
            parent_frame = parent_frame.context
          end

          push_data = Frame.new(
            query: query,
            path: push_key,
            ast_node: metadata[:ast_node],
            field: metadata[:field],
            object: metadata[:object],
            arguments: metadata[:arguments],
            parent_frame: parent_frame,
          )
        else
          # Custom key, no backtrace data for this
          nil
        end

        if push_data && multiplex
          push_storage = multiplex.context[:graphql_backtrace_contexts] ||= {}
          push_storage[push_key] = push_data
          multiplex.context[:last_graphql_backtrace_context] = push_data
        end

        if key == "execute_multiplex"
          multiplex_context = metadata[:multiplex].context
          begin
            yield
          rescue StandardError => err
            # This is an unhandled error from execution,
            # Re-raise it with a GraphQL trace.
            potential_context = multiplex_context[:last_graphql_backtrace_context]

            if potential_context.is_a?(GraphQL::Query::Context) ||
                potential_context.is_a?(GraphQL::Query::Context::FieldResolutionContext) ||
                potential_context.is_a?(Backtrace::Frame)
              raise TracedError.new(err, potential_context)
            else
              raise
            end
          ensure
            multiplex_context.delete(:graphql_backtrace_contexts)
            multiplex_context.delete(:last_graphql_backtrace_context)
          end
        else
          yield
        end
      end
    end
  end
end
