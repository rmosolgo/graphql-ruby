# frozen_string_literal: true
module GraphQL
  module Tracing
    # This produces a trace file for inspecting in the [Perfetto Trace Viewer](https://ui.perfetto.dev).
    #
    # To get the file, call {#write} on the trace.
    #
    # Use "trace modes" to configure this to run on command or on a sample of traffic.
    #
    # @example Writing trace output
    #
    #   result = MySchema.execute(...)
    #   result.query.trace.write(file: "tmp/trace.dump")
    #
    # @example Running this instrumenter when `trace: true` is present in the request
    #
    #   class MySchema < GraphQL::Schema
    #     # Only run this tracer when `context[:trace_mode]` is `:trace`
    #     trace_with GraphQL::Tracing::Perfetto, mode: :trace
    #   end
    #
    #   # In graphql_controller.rb:
    #
    #   context[:trace_mode] = params[:trace] ? :trace : nil
    #   result = MySchema.execute(query_str, context: context, variables: variables, ...)
    #   if context[:trace_mode] == :trace
    #     result.trace.write(file: ...)
    #   end
    #
    module PerfettoTrace
      # TODOs:
      # - Report object and arguments with field segments
      # - Make debug annotations visible on both parts when dataloader is involved
      # - Reconsider `begin_execute_field` and `end_execute_field` signatures
      # - Include resolved-to type in resolve_type debug annotations

      PROTOBUF_AVAILABLE = begin
        require "google/protobuf"
        true
      rescue LoadError
        false
      end

      if PROTOBUF_AVAILABLE
        require "graphql/tracing/perfetto_trace/trace_pb"
      end

      def self.included(_trace_class)
        if !PROTOBUF_AVAILABLE
          raise "#{self} can't be used because the `google-protobuf` gem wasn't available. Add it to your project, then try again."
        end
      end

      # @param name_prefix [String, nil] A prefix to remove from Source class names for readability
      # @param active_support_notifications_pattern [String, RegExp, false] A filter for `ActiveSupport::Notifications`, if it's present. Or `false` to skip subscribing.
      def initialize(name_prefix: nil, active_support_notifications_pattern: nil, **_rest)
        super
        @pid = Process.pid
        @flow_ids = Hash.new { |h, source_inst| h[source_inst] = [] }.compare_by_identity
        @clean_source_names = Hash.new do |h, source_class|
          h[source_class] = name_prefix ? source_class.name.sub(name_prefix, "") : source_class.name
        end.compare_by_identity
        @auth_packet_names = Hash.new do |h, graphql_type|
          h[graphql_type] = "Authorize #{graphql_type.graphql_name}"
        end.compare_by_identity
        @resolve_type_packet_names = Hash.new do |h, graphql_type|
          h[graphql_type] = "Resolve Type: #{graphql_type.graphql_name}"
        end.compare_by_identity
        @starting_objects = GC.stat(:total_allocated_objects)
        @objects_counter_id = :objects_counter.object_id
        @fibers_counter_id = :fibers_counter.object_id
        @fields_counter_id = :fields_counter.object_id
        @begin_validate = nil
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
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_COUNTER,
          track_uuid: @objects_counter_id,
          counter_value: count_allocations,
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
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_COUNTER,
          track_uuid: @fibers_counter_id,
          counter_value: count_fibers(0),
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
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_COUNTER,
          track_uuid: @fields_counter_id,
          counter_value: count_fields,
        )

        if defined?(ActiveSupport::Notifications) && active_support_notifications_pattern != false
          subscribe_to_active_support_notifications(active_support_notifications_pattern)
        end
      end

      def begin_multiplex(m)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          name: "Multiplex",
          debug_annotations: [
            payload_to_debug("query_string", m.queries.map(&:sanitized_query_string).join("\n\n"))
          ]
        )
        super
      end

      def end_multiplex(m)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
        )
        unsubscribe_from_active_support_notifications
        super
      end

      def begin_execute_field(result, result_name)
        packet = trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          name: "#{result.path.join(".")}.#{result_name}",
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
        )
        @packets << packet
        fiber_flow_stack << packet
        super
      end

      def end_execute_field(result, result_name, app_result)
        start_field = fiber_flow_stack.pop
        start_field.track_event = dup_with(start_field.track_event, { debug_annotations: [payload_to_debug("result", app_result)] })

        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id, @fields_counter_id],
          extra_counter_values: [count_allocations, count_fields],
        )
        super
      end

      def begin_analyze_multiplex(m, analyzers)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
          name: "Analysis",
          debug_annotations: [
            payload_to_debug("analyzers_count", analyzers.size),
            payload_to_debug("analyzers", analyzers),
          ]
        )
        super
      end

      def end_analyze_multiplex(m, analyzers)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
        )
        super
      end

      def begin_parse(str)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
          name: "Parse"
        )
        super
      end

      def end_parse(str)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
        )
        super
      end

      def begin_validate(query, validate)
        @packets << @begin_validate = trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
          name: "Validate",
          debug_annotations: [
            payload_to_debug("validate?", validate),
          ]
        )
        super
      end

      def end_validate(query, validate, is_valid)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
        )
        @begin_validate.track_event = dup_with(
          @begin_validate.track_event,
          {
            debug_annotations: [
              @begin_validate.track_event.debug_annotations.first,
              payload_to_debug("valid?", is_valid)
            ]
          }
        )
        super
      end

      def dataloader_spawn_execution_fiber(jobs)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_INSTANT,
          track_uuid: fid,
          name: "Create Execution Fiber",
          categories: ["dataloader"],
          extra_counter_track_uuids: [@fibers_counter_id, @objects_counter_id],
          extra_counter_values: [count_fibers(1), count_allocations]
        )
        @packets << TracePacket.new(
          track_descriptor: TrackDescriptor.new(
            uuid: fid,
            name: "Exec Fiber ##{fid}",
            parent_uuid: @did,
            child_ordering: TrackDescriptor::ChildTracksOrdering::CHRONOLOGICAL,
          )
        )
        super
      end

      def dataloader_spawn_source_fiber(pending_sources)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_INSTANT,
          track_uuid: fid,
          name: "Create Source Fiber",
          categories: ["dataloader"],
          extra_counter_track_uuids: [@fibers_counter_id, @objects_counter_id],
          extra_counter_values: [count_fibers(1), count_allocations]
        )
        @packets << TracePacket.new(
          track_descriptor: TrackDescriptor.new(
            uuid: fid,
            name: "Source Fiber ##{fid}",
            parent_uuid: @did,
            child_ordering: TrackDescriptor::ChildTracksOrdering::CHRONOLOGICAL,
          )
        )
        super
      end

      def dataloader_fiber_yield(source)
        if (ls = fiber_flow_stack.last)
          if (flow_id = ls.track_event.flow_ids.first)
            # got it
          else
            flow_id = ls.track_event.name.object_id
            ls.track_event = dup_with(ls.track_event, {flow_ids: [flow_id] }, delete_counters: true)
          end
          @flow_ids[source] << flow_id
          @packets << trace_packet(
            type: TrackEvent::Type::TYPE_SLICE_END,
            track_uuid: fid,
          )
        end
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_INSTANT,
          track_uuid: fid,
          name: "Fiber Yield",
          categories: ["dataloader"],
        )
        super
      end

      def dataloader_fiber_resume(source)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_INSTANT,
          track_uuid: fid,
          name: "Fiber Resume",
          categories: ["dataloader"],
        )
        if (ls = fiber_flow_stack.pop)
          @packets << packet = TracePacket.new(
            timestamp: ts,
            track_event: dup_with(ls.track_event, { type: TrackEvent::Type::TYPE_SLICE_BEGIN }),
            trusted_packet_sequence_id: @pid,
          )
          fiber_flow_stack << packet
        end
        super
      end

      def dataloader_fiber_exit
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_INSTANT,
          track_uuid: fid,
          name: "Fiber Exit",
          categories: ["dataloader"],
          extra_counter_track_uuids: [@fibers_counter_id],
          extra_counter_values: [count_fibers(-1)],
        )
        super
      end

      def begin_dataloader(dl)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_COUNTER,
          track_uuid: @fibers_counter_id,
          counter_value: count_fibers(1),
        )
        @did = fid
        @packets << TracePacket.new(
          track_descriptor: TrackDescriptor.new(
            uuid: @did,
            name: "Dataloader Fiber ##{@did}",
            parent_uuid: @main_fiber_id,
          )
        )
        super
      end

      def end_dataloader(dl)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_COUNTER,
          track_uuid: @fibers_counter_id,
          counter_value: count_fibers(-1),
        )
        super
      end

      def begin_dataloader_source(source)
        fds = @flow_ids[source]
        fds_copy = fds.dup
        fds.clear
        packet = trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          name: @clean_source_names[source.class],
          categories: ["dataloader"],
          flow_ids: fds_copy,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
          debug_annotations: [
            payload_to_debug("fetch keys", source.pending.values),
            *(source.instance_variables - [:@pending, :@fetching, :@results, :@dataloader]).map { |iv|
              payload_to_debug(iv.to_s, source.instance_variable_get(iv))
            }
          ]
        )
        @packets << packet
        fiber_flow_stack << packet
        super
      end

      def end_dataloader_source(source)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
          categories: ["dataloader"],
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
        )
        fiber_flow_stack.pop
        super
      end

      def begin_authorized(type, obj, ctx)
        packet = trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
          name: @auth_packet_names[type]
        )
        @packets << packet
        fiber_flow_stack << packet
        super
      end

      def end_authorized(type, obj, ctx, is_authorized)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
        )
        beg_auth = fiber_flow_stack.pop
        beg_auth.track_event = dup_with(beg_auth.track_event, { debug_annotations: [payload_to_debug("authorized?", is_authorized)] })
      end

      def begin_resolve_type(type, value, context)
        packet = trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
          name: @resolve_type_packet_names[type],
        )
        @packets << packet
        fiber_flow_stack << packet
        super
      end

      def end_resolve_type(type, value, context, resolved_type)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
        )
        rt_begin = fiber_flow_stack.pop
        rt_begin.track_event = dup_with(rt_begin.track_event, { debug_annotations: [payload_to_debug("resolved_type", resolved_type)] })
      end

      # Dump protobuf output in the specified file.
      # @param file [String] path to a file in a directory that already exists
      # @param debug_json [Boolean] True to print JSON instead of binary
      # @return [nil, String, Hash] If `file` was given, `nil`. If `file` was `nil`, a Hash if `debug_json: true`, else binary data.
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
          nil
        else
          data
        end
      end

      private

      def ts
        Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
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
          debug_annotation(k, :string_value, "::#{v.name}")
        when Symbol
          debug_annotation(k, :string_value, v.inspect)
        when Array
          debug_annotation(k, :array_values, v.map { |v2| payload_to_debug(nil, v2) }.compact)
        when Hash
          debug_annotation(k, :dict_entries, v.map { |k2, v2| payload_to_debug(k2, v2) }.compact)
        else
          debug_str = if defined?(ActiveRecord::Relation) && v.is_a?(ActiveRecord::Relation)
            "#{v.class}, .to_sql=#{v.to_sql.inspect}"
          else
            v.inspect
          end
          debug_annotation(k, :string_value, debug_str)
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

      def dup_with(message, attrs, delete_counters: false)
        new_attrs = message.to_h
        if delete_counters
          new_attrs.delete(:extra_counter_track_uuids)
          new_attrs.delete(:extra_counter_values)
        end
        new_attrs.merge!(attrs)
        message.class.new(**new_attrs)
      end

      def fiber_flow_stack
        Fiber[:graphql_flow_stack] ||= []
      end

      def trace_packet(event_attrs)
        TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(event_attrs),
          trusted_packet_sequence_id: @pid,
        )
      end

      def unsubscribe_from_active_support_notifications
        if defined?(@as_subscriber)
          ActiveSupport::Notifications.unsubscribe(@as_subscriber)
        end
      end

      def subscribe_to_active_support_notifications(pattern)
        @as_subscriber = ActiveSupport::Notifications.monotonic_subscribe(pattern) do |name, start, finish, id, payload|
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
  end
end
