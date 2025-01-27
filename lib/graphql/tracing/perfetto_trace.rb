# frozen_string_literal: true
require "graphql/tracing/perfetto_trace/trace_pb"

module GraphQL
  module Tracing
    # TODO:
    # - Support nested source calls
    # - Don't add flows to fields that don't pause
    # - Add snapshot tests using JSON output from Protobuf
    module PerfettoTrace
      def initialize(...)
        @pid = Process.pid
        @flow_ids = Hash.new { |h, source_inst| h[source_inst] = [] }.compare_by_identity
        @starting_objects = GC.stat(:total_allocated_objects)
        @objects_counter_id = :objects_counter.object_id
        @fibers_counter_id = :fibers_counter.object_id
        @fields_counter_id = :fields_counter.object_id
        @packets = []
        @packets << TracePacket.new(
          track_descriptor: TrackDescriptor.new(
            uuid: tid,
            name: "Main Thread",
            child_ordering: TrackDescriptor::ChildTracksOrdering::CHRONOLOGICAL,
          )
        )
        @main_fiber_id = fid
        @packets << TracePacket.new(
          track_descriptor: TrackDescriptor.new(
            parent_uuid: tid,
            uuid: fid,
            name: "Main Fiber",
            child_ordering: TrackDescriptor::ChildTracksOrdering::CHRONOLOGICAL,
          )
        )
        @packets << TracePacket.new(
          track_descriptor: TrackDescriptor.new(
            parent_uuid: tid,
            uuid: @objects_counter_id,
            name: "Allocations",
            counter: CounterDescriptor.new(
              unit: CounterDescriptor::Unit::UNIT_UNSPECIFIED,
              unit_name: "Objects"
            )
          )
        )
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_COUNTER,
            track_uuid: @objects_counter_id,
            counter_value: count_allocations,
          ),
          trusted_packet_sequence_id: @pid,
        )
        @packets << TracePacket.new(
          track_descriptor: TrackDescriptor.new(
            parent_uuid: tid,
            uuid: @fibers_counter_id,
            name: "Fibers",
            counter: CounterDescriptor.new(
              unit: CounterDescriptor::Unit::UNIT_COUNT,
            )
          )
        )
        @fibers_count = 0
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_COUNTER,
            track_uuid: @fibers_counter_id,
            counter_value: count_fibers(0),
          ),
          trusted_packet_sequence_id: @pid,
        )

        @packets << TracePacket.new(
          track_descriptor: TrackDescriptor.new(
            parent_uuid: tid,
            uuid: @fields_counter_id,
            name: "Resolved Fields",
            counter: CounterDescriptor.new(
              unit: CounterDescriptor::Unit::UNIT_COUNT,
            )
          )
        )

        @fields_count = -1
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_COUNTER,
            track_uuid: @fields_counter_id,
            counter_value: count_fields,
          ),
          trusted_packet_sequence_id: @pid,
        )

        if defined?(ActiveSupport::Notifications)
          @as_subscriber = ActiveSupport::Notifications.monotonic_subscribe do |name, start, finish, id, payload|
            count_allocations
            metadata = payload.map { |k, v| payload_to_debug(k, v) }
            metadata.compact!
            categories = [name]
            te = if metadata.empty?
              TrackEvent.new(
                type: TrackEvent::Type::TYPE_SLICE_BEGIN,
                track_uuid: fid,
                categories: categories,
                name: name,
              )
            else
              TrackEvent.new(
                type: TrackEvent::Type::TYPE_SLICE_BEGIN,
                track_uuid: fid,
                name: name,
                categories: categories,
                debug_annotations: metadata,
              )
            end
            @packets << TracePacket.new(
              timestamp: (start * 1_000_000_000).to_i,
              track_event: te,
              trusted_packet_sequence_id: @pid,
            )
            @packets << TracePacket.new(
              timestamp: (finish * 1_000_000_000).to_i,
              track_event: TrackEvent.new(
                type: TrackEvent::Type::TYPE_SLICE_END,
                track_uuid: fid,
                name: name,
              ),
              trusted_packet_sequence_id: @pid,
            )
          end
        end
      end

      def debug_annotation(name, value_key, value)
        if name
          DebugAnnotation.new(name: name, value_key => value)
        else
          DebugAnnotation.new(value_key => value)
        end
      end

      def payload_to_debug(k, v)
        case v
        when String
          debug_annotation(k, :string_value, v)
        when Float
          debug_annotation(k, :double_value, v)
        when Integer
          debug_annotation(k, :int_value, v)
        when true, false
          debug_annotation(k, :bool_value, v)
        when nil
          DebugAnnotation.new(name: k)
        when Module
          debug_annotation(k, :string_value, "::#{v.name}>")
        when Symbol
          debug_annotation(k, :string_value, v.inspect)
        when Array
          debug_annotation(k, :array_values, v.map { |v2| payload_to_debug(nil, v2) })
        when Hash
          debug_annotation(k, :dict_entries, v.map { |k2, v2| payload_to_debug(k2, v2) })
        else
          debug_annotation(k, :string_value, v.inspect)
        end
      end
      def count_allocations
        GC.stat(:total_allocated_objects) - @starting_objects
      end

      def count_fibers(diff)
        @fibers_count += diff
      end

      def count_fields
        @fields_count += 1
      end

      def begin_multiplex(m)
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_SLICE_BEGIN,
            track_uuid: fid,
            name: "Multiplex"
          ),
          trusted_packet_sequence_id: @pid,
        )
      end

      def end_multiplex(m)
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_SLICE_END,
            track_uuid: fid,
          ),
          trusted_packet_sequence_id: @pid,
        )
        if defined?(@as_subscriber)
          ActiveSupport::Notifications.unsubscribe(@as_subscriber)
        end
      end

      def begin_selection(result, result_name)
        @packets << Fiber[:graphql_last_selection] = TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_SLICE_BEGIN,
            track_uuid: fid,
            name: "#{result.path.join(".")}.#{result_name}",
            flow_ids: [rand(999_999)],
            extra_counter_track_uuids: [@objects_counter_id],
            extra_counter_values: [count_allocations],
          ),
          trusted_packet_sequence_id: @pid,
        )
      end

      def end_selection(result, result_name)
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_SLICE_END,
            track_uuid: fid,
            extra_counter_track_uuids: [@objects_counter_id, @fields_counter_id],
            extra_counter_values: [count_allocations, count_fields],
            terminating_flow_ids: [Fiber[:graphql_last_selection].track_event.flow_ids.first]
          ),
          trusted_packet_sequence_id: @pid,
        )
      end

      def begin_analysis(m)
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_SLICE_BEGIN,
            track_uuid: fid,
            extra_counter_track_uuids: [@objects_counter_id],
            extra_counter_values: [count_allocations],
            name: "Analysis"
          ),
          trusted_packet_sequence_id: @pid,
        )
      end

      def end_analysis(m)
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_SLICE_END,
            track_uuid: fid,
            extra_counter_track_uuids: [@objects_counter_id],
            extra_counter_values: [count_allocations],
          ),
          trusted_packet_sequence_id: @pid,
        )
      end

      def begin_parse(str)
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_SLICE_BEGIN,
            track_uuid: fid,
            extra_counter_track_uuids: [@objects_counter_id],
            extra_counter_values: [count_allocations],
            name: "Parse"
          ),
          trusted_packet_sequence_id: @pid,
        )
      end

      def end_parse(str)
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_SLICE_END,
            track_uuid: fid,
            extra_counter_track_uuids: [@objects_counter_id],
            extra_counter_values: [count_allocations],
          ),
          trusted_packet_sequence_id: @pid,
        )
      end

      def spawn_job_fiber
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_INSTANT,
            track_uuid: fid,
            name: "Create Job Fiber",
            categories: ["dataloader"],
            extra_counter_track_uuids: [@fibers_counter_id, @objects_counter_id],
            extra_counter_values: [count_fibers(1), count_allocations]
          ),
          trusted_packet_sequence_id: @pid,
        )
        @packets << TracePacket.new(
          track_descriptor: TrackDescriptor.new(
            uuid: fid,
            name: "Job Fiber ##{fid}",
            parent_uuid: @did,
            child_ordering: TrackDescriptor::ChildTracksOrdering::CHRONOLOGICAL,
          )
        )
      end

      def spawn_source_fiber
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_INSTANT,
            track_uuid: fid,
            name: "Create Source Fiber",
            categories: ["dataloader"],
            extra_counter_track_uuids: [@fibers_counter_id, @objects_counter_id],
            extra_counter_values: [count_fibers(1), count_allocations]
          ),
          trusted_packet_sequence_id: @pid,
        )
        @packets << TracePacket.new(
          track_descriptor: TrackDescriptor.new(
            uuid: fid,
            name: "Source Fiber ##{fid}",
            parent_uuid: @did,
            child_ordering: TrackDescriptor::ChildTracksOrdering::CHRONOLOGICAL,
          )
        )
      end

      def fiber_yield(source)
        if (ls = Fiber[:graphql_last_selection])
          @flow_ids[source] << ls.track_event.flow_ids.first
          @packets << TracePacket.new(
            timestamp: ts,
            track_event: TrackEvent.new(
              type: TrackEvent::Type::TYPE_SLICE_END,
              track_uuid: fid,
            ),
            trusted_packet_sequence_id: @pid,
          )
        end
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_INSTANT,
            track_uuid: fid,
            name: "Fiber Yield",
            categories: ["dataloader"],
          ),
          trusted_packet_sequence_id: @pid,
        )
      end

      def fiber_resume
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_INSTANT,
            track_uuid: fid,
            name: "Fiber Resume",
            categories: ["dataloader"],
          ),
          trusted_packet_sequence_id: @pid,
        )
        if (ls = Fiber[:graphql_last_selection])
          @packets << TracePacket.new(
            timestamp: ts,
            track_event: TrackEvent.new(
              type: TrackEvent::Type::TYPE_SLICE_BEGIN,
              track_uuid: fid,
              name: ls.track_event.name,
              flow_ids: ls.track_event.flow_ids.to_a,
            ),
            trusted_packet_sequence_id: @pid,
          )
        end
      end

      def fiber_exit
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_INSTANT,
            track_uuid: fid,
            name: "Fiber Exit",
            categories: ["dataloader"],
            extra_counter_track_uuids: [@fibers_counter_id],
            extra_counter_values: [count_fibers(-1)],
          ),
          trusted_packet_sequence_id: @pid,
        )
      end

      def begin_dataloader
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_COUNTER,
            track_uuid: @fibers_counter_id,
            counter_value: count_fibers(1),
          ),
          trusted_packet_sequence_id: @pid,
        )
        @did = fid
        @packets << TracePacket.new(
          track_descriptor: TrackDescriptor.new(
            uuid: fid,
            name: "Dataloader Fiber ##{fid}",
            parent_uuid: @main_fiber_id,
          )
        )
      end

      def end_dataloader
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_COUNTER,
            track_uuid: @fibers_counter_id,
            counter_value: count_fibers(-1),
          ),
          trusted_packet_sequence_id: @pid,
        )
      end

      def begin_source(source)
        fds = @flow_ids[source]
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_SLICE_BEGIN,
            track_uuid: fid,
            name: source.class.name,
            categories: ["dataloader"],
            flow_ids: fds,
            extra_counter_track_uuids: [@objects_counter_id],
            extra_counter_values: [count_allocations],
            debug_annotations: [
              DebugAnnotation.new(
                name: "fetch_keys",
                string_value: source.pending.values.inspect,
              ),
              *(source.instance_variables - [:@pending, :@fetching, :@results, :@dataloader]).map { |iv|
                DebugAnnotation.new(
                  name: iv.to_s,
                  string_value: source.instance_variable_get(iv)&.inspect,
                )
              }
            ]
          ),
          trusted_packet_sequence_id: @pid,
        )
      end

      def end_source(source)
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_SLICE_END,
            track_uuid: fid,
            categories: ["dataloader"],
            extra_counter_track_uuids: [@objects_counter_id],
            extra_counter_values: [count_allocations],
          ),
          trusted_packet_sequence_id: @pid,
        )
      end

      def write(file:)
        trace = Trace.new(
          packet: @packets,
        )
        data = Trace.encode(trace)
        File.write(file, data)
      end

      private

      def ts
        Process.clock_gettime(:CLOCK_MONOTONIC, :nanosecond)
      end

      def tid
        Thread.current.object_id
      end

      def fid
        Fiber.current.object_id
      end
    end
  end
end
