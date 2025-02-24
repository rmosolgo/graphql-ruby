# frozen_string_literal: true
require "graphql/tracing/perfetto_sampler/memory_backend"
require "graphql/tracing/perfetto_sampler/redis_backend"

module GraphQL
  module Tracing
    class PerfettoSampler
      # @param trace_mode [Symbol] When this is set as `context[:trace_mode]`, a profile will be taken
      # @param redis [Redis] If provided, profiles will be stored in Redis for later review
      # @param limit [Integer] A maximum number of profiles to store
      def self.use(schema, trace_mode: :perfetto_sample, memory: false, redis: nil, limit: nil)
        storage = if redis
          RedisBackend.new(redis: redis, limit: limit)
        elsif memory
          MemoryBackend.new(limit: limit)
        else
          raise ArgumentError, "Pass `redis: ...` to store traces in Redis for later review"
        end
        schema.perfetto_sampler = self.new(storage: storage)
        schema.trace_with(PerfettoTrace, mode: trace_mode, save_trace_mode: trace_mode)
      end

      def initialize(storage:)
        @storage = storage
      end

      # @return [String] ID of saved trace
      def save_trace(operation_name, duration_ms, timestamp, trace_data)
        @storage.save_trace(operation_name, duration_ms, timestamp, trace_data)
      end

      # @param last [Integer]
      # @param before [Integer] Timestamp in milliseconds since epoch
      # @return [Enumerable<StoredTrace>]
      def traces(last: nil, before: nil)
        @storage.traces(last: last, before: before)
      end

      # @return [StoredTrace, nil]
      def find_trace(id)
        @storage.find_trace(id)
      end

      # @return [void]
      def delete_trace(id)
        @storage.delete_trace(id)
      end

      # @return [void]
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
