# frozen_string_literal: true
# Legacy tracing:
require "graphql/tracing/active_support_notifications_tracing"
require "graphql/tracing/platform_tracing"
require "graphql/tracing/appoptics_tracing"
require "graphql/tracing/appsignal_tracing"
require "graphql/tracing/data_dog_tracing"
require "graphql/tracing/new_relic_tracing"
require "graphql/tracing/scout_tracing"
require "graphql/tracing/statsd_tracing"
require "graphql/tracing/prometheus_tracing"

# New Tracing:
require "graphql/tracing/platform_trace"
# require "graphql/tracing/active_support_notifications_trace"
require "graphql/tracing/appoptics_trace"
require "graphql/tracing/appsignal_trace"
require "graphql/tracing/data_dog_trace"
require "graphql/tracing/new_relic_trace"
require "graphql/tracing/scout_trace"
require "graphql/tracing/statsd_trace"
# require "graphql/tracing/prometheus_trace"
if defined?(PrometheusExporter::Server)
  require "graphql/tracing/prometheus_tracing/graphql_collector"
end

module GraphQL
  module Tracing
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

    NullTrace = Trace.new

    class LegacyTrace < Trace
      def lex(query_string:, &block)
        (@multiplex || @query).trace("lex", { query_string: query_string }, &block)
      end

      def parse(query_string:, &block)
        (@multiplex || @query).trace("parse", { query_string: query_string }, &block)
      end

      def validate(query:, validate:, &block)
        query.trace("validate", { validate: validate, query: query }, &block)
      end

      def analyze_multiplex(multiplex:, &block)
        multiplex.trace("analyze_multiplex", { multiplex: multiplex }, &block)
      end

      def analyze_query(query:, &block)
        query.trace("analyze_query", { query: query }, &block)
      end

      def execute_multiplex(multiplex:, &block)
        multiplex.trace("execute_multiplex", { multiplex: multiplex }, &block)
      end

      def execute_query(query:, &block)
        query.trace("execute_query", { query: query }, &block)
      end

      def execute_query_lazy(query:, multiplex:, &block)
        multiplex.trace("execute_query_lazy", { multiplex: multiplex, query: query }, &block)
      end

      def execute_field(field:, query:, ast_node:, arguments:, object:, &block)
        query.trace("execute_field", { field: field, query: query, ast_node: ast_node, arguments: arguments, object: object, owner: field.owner, path: query.context[:current_path] }, &block)
      end

      def execute_field_lazy(field:, query:, ast_node:, arguments:, object:, &block)
        query.trace("execute_field_lazy", { field: field, query: query, ast_node: ast_node, arguments: arguments, object: object, owner: field.owner, path: query.context[:current_path] }, &block)
      end

      def authorized(query:, type:, object:, &block)
        query.trace("authorized", { context: query.context, type: type, object: object, path: query.context[:current_path] }, &block)
      end

      def authorized_lazy(query:, type:, object:, &block)
        query.trace("authorized_lazy", { context: query.context, type: type, object: object, path: query.context[:current_path] }, &block)
      end

      def resolve_type(query:, type:, object:, &block)
        query.trace("resolve_type", { context: query.context, type: type, object: object, path: query.context[:current_path] }, &block)
      end

      def resolve_type_lazy(query:, type:, object:, &block)
        query.trace("resolve_type_lazy", { context: query.context, type: type, object: object, path: query.context[:current_path] }, &block)
      end
    end

    # Objects may include traceable to gain a `.trace(...)` method.
    # The object must have a `@tracers` ivar of type `Array<<#trace(k, d, &b)>>`.
    # @api private
    module Traceable
      # @param key [String] The name of the event in GraphQL internals
      # @param metadata [Hash] Event-related metadata (can be anything)
      # @return [Object] Must return the value of the block
      def trace(key, metadata, &block)
        return yield if @tracers.empty?
        call_tracers(0, key, metadata, &block)
      end

      private

      # If there's a tracer at `idx`, call it and then increment `idx`.
      # Otherwise, yield.
      #
      # @param idx [Integer] Which tracer to call
      # @param key [String] The current event name
      # @param metadata [Object] The current event object
      # @return Whatever the block returns
      def call_tracers(idx, key, metadata, &block)
        if idx == @tracers.length
          yield
        else
          @tracers[idx].trace(key, metadata) { call_tracers(idx + 1, key, metadata, &block) }
        end
      end
    end

    module NullTracer
      module_function
      def trace(k, v)
        yield
      end
    end
  end
end
