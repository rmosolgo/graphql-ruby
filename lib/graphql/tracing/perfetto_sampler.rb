# frozen_string_literal: true
require "graphql/tracing/perfetto_sampler/memory_backend"

module GraphQL
  module Tracing
    class PerfettoSampler
      def self.use(schema, trace_mode: :perfetto_sample, memory: false, active_record: true)
        storage = if memory
          MemoryBackend.new
        else
          raise ArgumentError, "A storage option must be chosen"
        end
        schema.perfetto_sampler = self.new(storage: storage)
        schema.trace_with(PerfettoTrace, mode: trace_mode, save_trace_mode: trace_mode)
      end

      def initialize(storage:)
        @storage = storage
      end

      def save_trace(operation_name, duration_ms, timestamp, trace_data)
        @storage.save_trace(operation_name, duration_ms, timestamp, trace_data)
      end

      def traces
        @storage.traces
      end

      def find_trace(id)
        @storage.find_trace(id)
      end

      def delete_trace(id)
        @storage.delete_trace(id)
      end

      def delete_all_traces
        @storage.delete_all_traces
      end

      class StoredTrace
        def initialize(id:, operation_name:, duration_ms:, timestamp:, trace_data:)
          @id = id
          @operation_name = operation_name
          @duration_ms = duration_ms
          @timestamp = timestamp
          @trace_data = trace_data
        end

        attr_reader :id, :operation_name, :duration_ms, :timestamp, :trace_data
      end
    end
  end
end
