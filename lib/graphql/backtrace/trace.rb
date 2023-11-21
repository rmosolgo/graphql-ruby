# frozen_string_literal: true
module GraphQL
  class Backtrace
    module Trace
      def initialize(*args, **kwargs, &block)
        @__backtrace_contexts = {}
        @__backtrace_last_context = nil
        super
      end

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
        potential_context = @__backtrace_last_context
        if potential_context.is_a?(GraphQL::Query::Context) ||
            potential_context.is_a?(Backtrace::Frame)
          raise TracedError.new(err, potential_context)
        else
          raise
        end
      end

      private

      def push_query_backtrace_context(query)
        push_data = query
        push_key = []
        @__backtrace_contexts[push_key] = push_data
        @__backtrace_last_context = push_data
      end

      def push_field_backtrace_context(field, query, ast_node, arguments, object)
        push_key = query.context[:current_path]
        push_storage = @__backtrace_contexts
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
        @__backtrace_last_context = push_data
      end

    end
  end
end
