# frozen_string_literal: true
# A stub for the Opentelemetry agent, so we can make assertions about how it is used
if defined?(OpenTelemetry)
  raise "Expected Opentelemetry to be undefined, so that we could define a stub for it."
end

module OpenTelemetry
  module Instrumentation
    module GraphQL
      class Instrumentation
        EVENTS = []
        class << self
          def instance
            @instance ||= new
          end

          def clear_all
            EVENTS.clear
          end
        end

        def tracer
          @tracer ||= DummyTracer.new
        end

        def config
          @config ||= {
            schemas: [],
            enable_platform_field: true,
            enable_platform_authorized: true,
            enable_platform_resolve_type: true
          }
        end
      end

      class DummyTracer
        class TestSpan
          def add_event(name, attributes:)
            self
          end
        end

        def in_span(name, attributes: nil, links: nil, start_timestamp: nil, kind: nil)
          OpenTelemetry::Instrumentation::GraphQL::Instrumentation::EVENTS << name

          yield(TestSpan.new, {})
        end
      end
    end
  end
end
