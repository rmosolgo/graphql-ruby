# frozen_string_literal: true
require "graphql/tracing/trace"
require "graphql/tracing/legacy_trace"

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
require "graphql/tracing/active_support_notifications_trace"
require "graphql/tracing/platform_trace"
require "graphql/tracing/appoptics_trace"
require "graphql/tracing/appsignal_trace"
require "graphql/tracing/data_dog_trace"
require "graphql/tracing/new_relic_trace"
require "graphql/tracing/notifications_trace"
require "graphql/tracing/scout_trace"
require "graphql/tracing/statsd_trace"
require "graphql/tracing/prometheus_trace"
if defined?(PrometheusExporter::Server)
  require "graphql/tracing/prometheus_tracing/graphql_collector"
end

module GraphQL
  module Tracing
    NullTrace = Trace.new

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
