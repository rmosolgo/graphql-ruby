# frozen_string_literal: true
module GraphQL
  module Tracing
    # This is the base class for a `trace` instance whose methods are called during query execution.
    # "Trace modes" are subclasses of this with custom tracing modules mixed in.
    #
    # A trace module may implement any of the methods on `Trace`, being sure to call `super`
    # to continue any tracing hooks and call the actual runtime behavior. See {GraphQL::Backtrace::Trace} for example.
    #
    class Trace
      # @param multiplex [GraphQL::Execution::Multiplex, nil]
      # @param query [GraphQL::Query, nil]
      def initialize(multiplex: nil, query: nil, **_options)
        @multiplex = multiplex
        @query = query
      end

      def lex(query_string:)
        yield
      end

      def parse(query_string:)
        yield
      end

      def validate(query:, validate:)
        yield
      end

      def analyze_multiplex(multiplex:)
        yield
      end

      def analyze_query(query:)
        yield
      end

      def execute_multiplex(multiplex:)
        yield
      end

      def execute_query(query:)
        yield
      end

      def execute_query_lazy(query:, multiplex:)
        yield
      end

      def execute_field(field:, query:, ast_node:, arguments:, object:)
        yield
      end

      def execute_field_lazy(field:, query:, ast_node:, arguments:, object:)
        yield
      end

      def authorized(query:, type:, object:)
        yield
      end

      def authorized_lazy(query:, type:, object:)
        yield
      end

      def resolve_type(query:, type:, object:)
        yield
      end

      def resolve_type_lazy(query:, type:, object:)
        yield
      end
    end
  end
end
