# frozen_string_literal: true

require "graphql/tracing/monitor_trace"

module GraphQL
  module Tracing
    # A tracer for reporting GraphQL-Ruby times to Statsd.
    # Passing any Statsd client that implements `.time(name) { ... }`
    # and `.timing(name, ms)` will work.
    #
    # @example Installing this tracer
    #   # eg:
    #   # $statsd = Statsd.new 'localhost', 9125
    #   class MySchema < GraphQL::Schema
    #     use GraphQL::Tracing::StatsdTrace, statsd: $statsd
    #   end
    StatsdTrace = MonitorTrace.create_module("statsd")
    module StatsdTrace
      class StatsdMonitor < MonitorTrace::Monitor
        def initialize(statsd:, **_rest)
          @statsd = statsd
          super
        end

        attr_reader :statsd

        def instrument(keyword, object)
          @statsd.time(name_for(keyword, object)) do
            yield
          end
        end

        include MonitorTrace::Monitor::GraphQLPrefixNames

        class Event < MonitorTrace::Monitor::Event
          def start
            @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          end

          def finish
            elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time
            @monitor.statsd.timing(@monitor.name_for(keyword, object), elapsed)
          end
        end
      end
    end
  end
end
