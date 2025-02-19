# frozen_string_literal: true

module GraphQL
  module Tracing
    class PerfettoSampler
      class RedisBackend
        KEY_PREFIX = "gql:trace:"
        def initialize(redis:)
          @redis = redis
        end

        def traces
          keys = @redis.scan_each(match: "#{KEY_PREFIX}*")
          keys.map do |k|
            h = @redis.hgetall(k)
            StoredTrace.new(
              id: k.sub(KEY_PREFIX, ""),
              operation_name: h["operation_name"],
              duration_ms: h["duration_ms"].to_f,
              timestamp: Time.at(h["timestamp"].to_i),
              trace_data: h["trace_data"],
            )
          end
        end

        def delete_trace(id)
          @redis.del("#{KEY_PREFIX}#{id}")
          nil
        end

        def find_trace(id)
          redis_h = @redis.hgetall("#{KEY_PREFIX}#{id}")
          if redis_h
            StoredTrace.new(
              id: id,
              operation_name: redis_h["operation_name"],
              duration_ms: redis_h["duration_ms"].to_f,
              timestamp: Time.at(redis_h["timestamp"].to_i),
              trace_data: redis_h["trace_data"],
            )
          else
            nil
          end
        end

        def save_trace(operation_name, duration_ms, timestamp, trace_data)
          id = (timestamp.to_i * 1000) + rand(1000)
          @redis.hmset("#{KEY_PREFIX}#{id}",
            "operation_name", operation_name,
            "duration_ms", duration_ms,
            "timestamp", timestamp.to_i,
            "trace_data", trace_data,
          )
          nil
        end
      end
    end
  end
end
