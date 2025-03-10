# frozen_string_literal: true

module GraphQL
  module Tracing
    # This module is the basis for Ruby-level integration with third-party monitoring platforms.
    # Platform-specific traces include this module and implement an adapter.
    #
    # @see ActiveSupportNotificationsTrace Integration via ActiveSupport::Notifications, an alternative approach.
    module MonitorTrace
      class Monitor
        def initialize(set_transaction_name:)
          @set_transaction_name = set_transaction_name
          @platform_field_key_cache = Hash.new { |h, k| h[k] = platform_field_key(k) }.compare_by_identity
          @platform_authorized_key_cache = Hash.new { |h, k| h[k] = platform_authorized_key(k) }.compare_by_identity
          @platform_resolve_type_key_cache = Hash.new { |h, k| h[k] = platform_resolve_type_key(k) }.compare_by_identity
          @platform_source_class_key_cache = Hash.new { |h, source_cls| h[source_cls] = platform_source_class_key(source_cls) }.compare_by_identity
        end

        def instrument(keyword, object, &block)
          raise "Implement #{self.class}#instrument to measure the block"
        end

        def start_event(keyword, object)
          ev = self.class::Event.new(self, keyword, object)
          ev.start
          ev
        end

        # Get the transaction name based on the operation type and name if possible, or fall back to a user provided
        # one. Useful for anonymous queries.
        def transaction_name(query)
          selected_op = query.selected_operation
          txn_name = if selected_op
            op_type = selected_op.operation_type
            op_name = selected_op.name || fallback_transaction_name(query.context) || "anonymous"
            "#{op_type}.#{op_name}"
          else
            "query.anonymous"
          end
          "GraphQL/#{txn_name}"
        end

        def fallback_transaction_name(context)
          context[:tracing_fallback_transaction_name]
        end

        def name_for(keyword, object)
          case keyword
          when :execute_field
            @platform_field_key_cache[object]
          when :authorized
            @platform_authorized_key_cache[object]
          when :resolve_type
            @platform_resolve_type_key_cache[object]
          when :dataloader_source
            @platform_source_class_key_cache[object.class]
          when :parse then self.class::PARSE_NAME
          when :lex then self.class::LEX_NAME
          when :execute then self.class::EXECUTE_NAME
          when :analyze then self.class::ANALYZE_NAME
          when :validate then self.class::VALIDATE_NAME
          else
            raise "No name for #{keyword.inspect}"
          end
        end

        class Event
          def initialize(engine, keyword, object)
            @engine = engine
            @keyword = keyword
            @object = object
          end

          attr_reader :keyword, :object

          def start
            raise "Implement #{self.class}#start to begin a new event (#{inspect})"
          end

          def finish
            raise "Implement #{self.class}#finish to end this event (#{inspect})"
          end
        end
      end

      # @param set_transaction_name [Boolean] If `true`, use the GraphQL operation name as the request name on the monitoring platform
      # @param trace_scalars [Boolean] If `true`, leaf fields will be traced too (Scalars _and_ Enums)
      # @param trace_authorized [Boolean] If `false`, skip tracing `authorized?` calls
      # @param trace_resolve_type [Boolean] If `false`, skip tracing `resolve_type?` calls
      def initialize(set_transaction_name: false, trace_scalars: false, trace_authorized: true, trace_resolve_type: true, **rest)
        @trace_scalars = trace_scalars
        @trace_authorized = trace_authorized
        @trace_resolve_type = trace_resolve_type
        @set_transaction_name = set_transaction_name
        super
      end

      def parse(query_string:)
        @monitor.instrument(:parse, query_string) do
          super
        end
      end

      def lex(query_string:)
        @monitor.instrument(:lex, query_string) do
          super
        end
      end

      def validate(query:, validate:)
        @monitor.instrument(:validate, query) do
          super
        end
      end

      def begin_analyze_multiplex(multiplex, analyzers)
        begin_notifications_event(:analyze, nil)
        super
      end

      def end_analyze_multiplex(multiplex, analyzers)
        finish_notifications_event
        super
      end

      def execute_multiplex(multiplex:)
        @monitor.instrument(:execute, multiplex) do
          super
        end
      end

      def begin_execute_field(field, object, arguments, query)
        return_type = field.type.unwrap
        trace_field = if return_type.kind.scalar? || return_type.kind.enum?
          (field.trace.nil? && @trace_scalars) || field.trace
        else
          true
        end

        if trace_field
          begin_notifications_event(:execute_field, field)
        end
        super
      end

      def end_execute_field(field, object, arguments, query, result)
        finish_notifications_event
        super
      end

      def dataloader_fiber_yield(source)
        Fiber[PREVIOUS_EV_KEY] = finish_notifications_event
        super
      end

      def dataloader_fiber_resume(source)
        prev_ev = Fiber[PREVIOUS_EV_KEY]
        begin_notifications_event(prev_ev.keyword, prev_ev.object)
        super
      end

      def begin_authorized(type, object, context)
        @trace_authorized && begin_notifications_event(:authorized, type)
        super
      end

      def end_authorized(type, object, context, result)
        finish_notifications_event
        super
      end

      def begin_resolve_type(type, value, context)
        @trace_resolve_type && begin_notifications_event(:resolve_type, type)
        super
      end

      def end_resolve_type(type, value, context, resolved_type)
        finish_notifications_event
        super
      end

      def begin_dataloader_source(source)
        begin_notifications_event(:dataloader_source, source)
        super
      end

      def end_dataloader_source(source)
        finish_notifications_event
        super
      end

      CURRENT_EV_KEY = :__notifications_graphql_trace_event
      PREVIOUS_EV_KEY = :__notifications_graphql_trace_previous_event

      private

      def begin_notifications_event(keyword, object)
        Fiber[CURRENT_EV_KEY] = @monitor.start_event(keyword, object)
      end

      def finish_notifications_event
        if ev = Fiber[CURRENT_EV_KEY]
          ev.finish
          # Use `false` to prevent grabbing an event from a parent fiber
          Fiber[CURRENT_EV_KEY] = false
          ev
        end
      end
    end
  end
end
