# frozen_string_literal: true

module GraphQL
  module Tracing
    class PerfettoSampler
      # An in-memory trace storage backend. Suitable for testing and development only.
      # It won't work for multi-process deployments and everything is erased when the app is restarted.
      class MemoryBackend
        def initialize
          @traces = {}
        end

        def traces
          @traces.values
        end

        def find_trace(id)
          @traces[id]
        end

        def delete_trace(id)
          @traces.delete(id)
          nil
        end

        def delete_all_traces
          @traces.clear
          nil
        end

        def save_trace(operation_name, duration, timestamp, trace_data)
          id = @traces.size
          @traces[id] = PerfettoSampler::StoredTrace.new(
            id: id,
            operation_name: operation_name,
            duration_ms: duration,
            timestamp: timestamp,
            trace_data: trace_data
          )
          id
        end
      end
    end
  end
end
