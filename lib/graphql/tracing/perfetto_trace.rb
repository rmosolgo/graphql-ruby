# frozen_string_literal: true
require "graphql/tracing/perfetto_trace/trace_pb"

module GraphQL
  module Tracing
    module PerfettoTrace
      def initialize(name_prefix: nil, **_rest)
        super
        @pid = Process.pid
        @flow_ids = Hash.new { |h, source_inst| h[source_inst] = [] }.compare_by_identity
        @clean_source_names = Hash.new do |h, source_class|
          h[source_class] = name_prefix ? source_class.name.sub(name_prefix, "") : source_class.name
        end.compare_by_identity
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
                extra_counter_track_uuids: [@objects_counter_id],
                extra_counter_values: [count_allocations]
              ),
              trusted_packet_sequence_id: @pid,
            )
          end
        end
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

      def begin_execute_field(result, result_name)
        packet = TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_SLICE_BEGIN,
            track_uuid: fid,
            name: "#{result.path.join(".")}.#{result_name}",
            extra_counter_track_uuids: [@objects_counter_id],
            extra_counter_values: [count_allocations],
          ),
          trusted_packet_sequence_id: @pid,
        )
        @packets << packet
        fiber_flow_stack << packet
      end

      def end_execute_field(result, result_name)
        track_event = if (start_field = fiber_flow_stack.pop) && (flow_id = start_field.track_event.flow_ids&.first)
          TrackEvent.new(
            type: TrackEvent::Type::TYPE_SLICE_END,
            track_uuid: fid,
            extra_counter_track_uuids: [@objects_counter_id, @fields_counter_id],
            extra_counter_values: [count_allocations, count_fields],
            terminating_flow_ids: [flow_id]
          )
        else
          TrackEvent.new(
            type: TrackEvent::Type::TYPE_SLICE_END,
            track_uuid: fid,
            extra_counter_track_uuids: [@objects_counter_id, @fields_counter_id],
            extra_counter_values: [count_allocations, count_fields],
          )
        end
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: track_event,
          trusted_packet_sequence_id: @pid,
        )
      end

      def begin_analyze_multiplex(m)
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

      def end_analyze_multiplex(m)
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

      def dataloader_spawn_execution_fiber(jobs)
        @packets << TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_INSTANT,
            track_uuid: fid,
            name: "Create Execution Fiber",
            categories: ["dataloader"],
            extra_counter_track_uuids: [@fibers_counter_id, @objects_counter_id],
            extra_counter_values: [count_fibers(1), count_allocations]
          ),
          trusted_packet_sequence_id: @pid,
        )
        @packets << TracePacket.new(
          track_descriptor: TrackDescriptor.new(
            uuid: fid,
            name: "Exec Fiber ##{fid}",
            parent_uuid: @did,
            child_ordering: TrackDescriptor::ChildTracksOrdering::CHRONOLOGICAL,
          )
        )
      end

      def dataloader_spawn_source_fiber(pending_sources)
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

      def dataloader_fiber_yield(source)
        if (ls = fiber_flow_stack.last)
          if (flow_id = ls.track_event.flow_ids.first)
            # got it
          else
            flow_id = rand(999_999)
            ls.track_event = dup_with(ls.track_event, {flow_ids: [flow_id] })
          end
          @flow_ids[source] << flow_id
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

      def dataloader_fiber_resume(source)
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
        if (ls = fiber_flow_stack.last)
          @packets << TracePacket.new(
            timestamp: ts,
            track_event: dup_with(ls.track_event, { type: TrackEvent::Type::TYPE_SLICE_BEGIN }),
            trusted_packet_sequence_id: @pid,
          )
        end
      end

      def dataloader_fiber_exit
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

      def begin_dataloader_source(source)
        fds = @flow_ids[source]
        fds_copy = fds.dup
        fds.clear
        packet = TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(
            type: TrackEvent::Type::TYPE_SLICE_BEGIN,
            track_uuid: fid,
            name: @clean_source_names[source.class],
            categories: ["dataloader"],
            flow_ids: fds_copy,
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
        @packets << packet
        fiber_flow_stack << packet
      end

      def end_dataloader_source(source)
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
        fiber_flow_stack.pop
      end

      def write(file:, debug_json: false)
        trace = Trace.new(
          packet: @packets,
        )
        data = if debug_json
          small_json = Trace.encode_json(trace)
          JSON.pretty_generate(JSON.parse(small_json))
        else
          Trace.encode(trace)
        end

        if file
          File.write(file, data, mode: 'wb')
        else
          data
        end
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
          debug_annotation(k, :array_values, v.map { |v2| payload_to_debug(nil, v2) }.compact)
        when Hash
          debug_annotation(k, :dict_entries, v.map { |k2, v2| payload_to_debug(k2, v2) }.compact)
        else
          nil
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

      def dup_with(message, attrs)
        new_attrs = message.to_h
        new_attrs.merge!(attrs)
        message.class.new(**new_attrs)
      end

      def fiber_flow_stack
        Fiber[:graphql_flow_stack] ||= []
      end
    end
  end
end
