# frozen_string_literal: true

require "graphql/tracing/monitor_trace"

module GraphQL
  module Tracing
    # A tracer for reporting GraphQL-Ruby times to Prometheus.
    #
    # The PrometheusExporter server must be run with a custom type collector that extends `GraphQL::Tracing::PrometheusTracing::GraphQLCollector`.
    #
    # @example Adding this trace to your schema
    #   require 'prometheus_exporter/client'
    #
    #   class MySchema < GraphQL::Schema
    #     trace_with GraphQL::Tracing::PrometheusTrace
    #   end
    #
    # @example Running a custom type collector
    #   # lib/graphql_collector.rb
    #   if defined?(PrometheusExporter::Server)
    #     require 'graphql/tracing'
    #
    #     class GraphQLCollector < GraphQL::Tracing::PrometheusTrace::GraphQLCollector
    #     end
    #   end
    #
    #    # Then run:
    #    # bundle exec prometheus_exporter -a lib/graphql_collector.rb
    PrometheusTrace = MonitorTrace.create_module("prometheus")
    module PrometheusTrace
      if defined?(PrometheusExporter::Server)
        autoload :GraphQLCollector, "graphql/tracing/prometheus_trace/graphql_collector"
      end

      def initialize(client: PrometheusExporter::Client.default, keys_whitelist: [:execute_field], collector_type: "graphql", **rest)
        @prometheus_client = client
        @prometheus_keys_whitelist = keys_whitelist.map(&:to_sym) # handle previous string keys
        @prometheus_collector_type = collector_type
        setup_prometheus_monitor(**rest)
        super
      end

      attr_reader :prometheus_collector_type, :prometheus_client, :prometheus_keys_whitelist

      class PrometheusMonitor < MonitorTrace::Monitor
        def instrument(keyword, object)
          if active?(keyword)
            start = gettime
            result = yield
            duration = gettime - start
            send_json(duration, keyword, object)
            result
          else
            yield
          end
        end

        def active?(keyword)
          @trace.prometheus_keys_whitelist.include?(keyword)
        end

        def gettime
          ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
        end

        def send_json(duration, keyword, object)
          event_name = name_for(keyword, object)
          @trace.prometheus_client.send_json(
            type: @trace.prometheus_collector_type,
            duration: duration,
            platform_key: event_name,
            key: keyword
          )
        end

        include MonitorTrace::Monitor::GraphQLPrefixNames

        class Event < MonitorTrace::Monitor::Event
          def start
            @start_time = @monitor.gettime
          end

          def finish
            if @monitor.active?(keyword)
              duration = @monitor.gettime - @start_time
              @monitor.send_json(duration, keyword, object)
            end
          end
        end
      end
    end
  end
end
