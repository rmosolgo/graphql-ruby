# frozen_string_literal: true

require "graphql/tracing/platform_trace"

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

        PARSE_NAME = "graphql.parse"
        LEX_NAME = "graphql.lex"
        VALIDATE_NAME = "graphql.validate"
        EXECUTE_NAME = "graphql.execute"
        ANALYZE_NAME = "graphql.analyze"

        def platform_field_key(field)
          "graphql.#{field.path}"
        end

        def platform_authorized_key(type)
          "graphql.authorized.#{type.graphql_name}"
        end

        def platform_resolve_type_key(type)
          "graphql.resolve_type.#{type.graphql_name}"
        end

        def platform_source_class_key(source_class)
          "graphql.fetch.#{source_class.name.gsub("::", "_")}"
        end

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
