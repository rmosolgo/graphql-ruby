# frozen_string_literal: true
require "ostruct"

module GraphQL
  module Tracing
    class PerfettoSampler
      def self.use(schema, trace_mode: :perfetto_sample)
        schema.perfetto_sampler = self.new
        schema.trace_with(PerfettoTrace, mode: trace_mode, save_trace_mode: trace_mode)
      end

      $traces = []

      def initialize
        @traces = []
      end

      def save_trace(operation_name, duration_ms, timestamp, trace_data)
        $traces << OpenStruct.new(id: $traces.size, operation_name: operation_name, duration_ms: duration_ms, timestamp: timestamp, trace_data: trace_data)
      end

      def traces
        $traces
      end

      def find_trace(id)
        $traces[id]
      end
    end
  end
end
