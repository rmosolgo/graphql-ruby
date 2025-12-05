# frozen_string_literal: true
require "graphql/tracing/detailed_trace/memory_backend"
require "graphql/tracing/detailed_trace/redis_backend"

module GraphQL
  module Tracing
    # `DetailedTrace` can make detailed profiles for a subset of production traffic.
    #
    # When `MySchema.detailed_trace?(query)` returns `true`, a profiler-specific `trace_mode: ...` will be used for the query,
    # overriding the one in `context[:trace_mode]`.
    #
    # By default, the detailed tracer calls `.inspect` on application objects returned from fields. You can customize
    # this behavior by extending {DetailedTrace} and overriding {#inspect_object}. You can opt out of debug annotations
    # entirely with `use ..., debug: false` or for a single query with `context: { detailed_trace_debug: false }`.
    #
    # __Redis__: The sampler stores its results in a provided Redis database. Depending on your needs,
    # You can configure this database to retain all data (persistent) or to expire data according to your rules.
    # If you need to save traces indefinitely, you can download them from Perfetto after opening them there.
    #
    # @example Adding the sampler to your schema
    #   class MySchema < GraphQL::Schema
    #     # Add the sampler:
    #     use GraphQL::Tracing::DetailedTrace, redis: Redis.new(...), limit: 100
    #
    #     # And implement this hook to tell it when to take a sample:
    #     def self.detailed_trace?(query)
    #       # Could use `query.context`, `query.selected_operation_name`, `query.query_string` here
    #       # Could call out to Flipper, etc
    #       rand <= 0.000_1 # one in ten thousand
    #     end
    #   end
    #
    # @see Graphql::Dashboard GraphQL::Dashboard for viewing stored results
    #
    # @example Customizing debug output in traces
    #   class CustomDetailedTrace < GraphQL::Tracing::DetailedTrace
    #     def inspect_object(object)
    #       if object.is_a?(SomeThing)
    #         # handle it specially ...
    #       else
    #         super
    #        end
    #     end
    #   end
    #
    # @example disabling debug annotations completely
    #    use DetailedTrace, debug: false, ...
    #
    # @example disabling debug annotations for one query
    #    MySchema.execute(query_str, context: { detailed_trace_debug: false })
    #
    class DetailedTrace
      # @param redis [Redis] If provided, profiles will be stored in Redis for later review
      # @param limit [Integer] A maximum number of profiles to store
      # @param debug [Boolean] if `false`, it won't create `debug` annotations in Perfetto traces (reduces overhead)
      def self.use(schema, trace_mode: :profile_sample, memory: false, debug: debug?, redis: nil, limit: nil)
        storage = if redis
          RedisBackend.new(redis: redis, limit: limit)
        elsif memory
          MemoryBackend.new(limit: limit)
        else
          raise ArgumentError, "Pass `redis: ...` to store traces in Redis for later review"
        end
        detailed_trace = self.new(storage: storage, trace_mode: trace_mode, debug: debug)
        schema.detailed_trace = detailed_trace
        schema.trace_with(PerfettoTrace, mode: trace_mode, save_profile: true)
      end

      def initialize(storage:, trace_mode:, debug:)
        @storage = storage
        @trace_mode = trace_mode
        @debug = debug
      end

      # @return [Symbol] The trace mode to use when {Schema.detailed_trace?} returns `true`
      attr_reader :trace_mode

      # @return [String] ID of saved trace
      def save_trace(operation_name, duration_ms, begin_ms, trace_data)
        @storage.save_trace(operation_name, duration_ms, begin_ms, trace_data)
      end

      # @return [Boolean]
      def debug?
        @debug
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

      def inspect_object(object)
        self.class.inspect_object(object)
      end

      def self.inspect_object(object)
        if defined?(ActiveRecord::Relation) && object.is_a?(ActiveRecord::Relation)
          "#{object.class}, .to_sql=#{object.to_sql.inspect}"
        else
          object.inspect
        end
      end

      # Default debug setting
      # @return [true]
      def self.debug?
        true
      end

      class StoredTrace
        def initialize(id:, operation_name:, duration_ms:, begin_ms:, trace_data:)
          @id = id
          @operation_name = operation_name
          @duration_ms = duration_ms
          @begin_ms = begin_ms
          @trace_data = trace_data
        end

        attr_reader :id, :operation_name, :duration_ms, :begin_ms, :trace_data
      end
    end
  end
end
