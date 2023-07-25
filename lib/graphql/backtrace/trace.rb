# frozen_string_literal: true
module GraphQL
  class Backtrace
    module Trace
      def validate(query:, validate:)
        if query.multiplex
          push_query_backtrace_context(query)
        end
        super
      end

      def analyze_query(query:)
        if query.multiplex # missing for stand-alone static validation
          push_query_backtrace_context(query)
        end
        super
      end

      def execute_query(query:)
        push_query_backtrace_context(query)
        super
      end

      def execute_query_lazy(query:, multiplex:)
        query ||= multiplex.queries.first
        push_query_backtrace_context(query)
        super
      end

      def execute_field(field:, query:, ast_node:, arguments:, object:)
        push_field_backtrace_context(field, query, ast_node, arguments, object)
        super
      end

      def execute_field_lazy(field:, query:, ast_node:, arguments:, object:)
        push_field_backtrace_context(field, query, ast_node, arguments, object)
        super
      end

      def execute_multiplex(multiplex:)
        super
      rescue StandardError => err
        # This is an unhandled error from execution,
        # Re-raise it with a GraphQL trace.
        multiplex_context = multiplex.context
        potential_context = multiplex_context[:last_graphql_backtrace_context]

        if potential_context.is_a?(GraphQL::Query::Context) ||
            potential_context.is_a?(Backtrace::Frame)
          raise TracedError.new(err, potential_context)
        else
          raise
        end
      ensure
        multiplex_context = multiplex.context
        multiplex_context.delete(:graphql_backtrace_contexts)
        multiplex_context.delete(:last_graphql_backtrace_context)
      end

      private

      def push_query_backtrace_context(query)
        push_data = query
        multiplex = query.multiplex
        push_key = []
        push_storage = multiplex.context[:graphql_backtrace_contexts] ||= {}
        push_storage[push_key] = push_data
        multiplex.context[:last_graphql_backtrace_context] = push_data
      end

      def push_field_backtrace_context(field, query, ast_node, arguments, object)
        multiplex = query.multiplex
        push_key = query.context[:current_path]
        push_storage = multiplex.context[:graphql_backtrace_contexts]
        parent_frame = push_storage[push_key[0..-2]]

        if parent_frame.is_a?(GraphQL::Query)
          parent_frame = parent_frame.context
        end

        push_data = Frame.new(
          query: query,
          path: push_key,
          ast_node: ast_node,
          field: field,
          object: object,
          arguments: arguments,
          parent_frame: parent_frame,
        )

        push_storage[push_key] = push_data
        multiplex.context[:last_graphql_backtrace_context] = push_data
      end
    end
  end
end
