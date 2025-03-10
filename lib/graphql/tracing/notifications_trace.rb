# frozen_string_literal: true

require "graphql/tracing/platform_trace"

module GraphQL
  module Tracing
    # This implementation forwards events to a notification handler (i.e.
    # ActiveSupport::Notifications or Dry::Monitor::Notifications)
    # with a `graphql` suffix.
    module NotificationsTrace
      class Engine
        def initialize(set_transaction_name:)
          @set_transaction_name = set_transaction_name
          @platform_field_key_cache = Hash.new { |h, k| h[k] = platform_field_key(k) }.compare_by_identity
          @platform_authorized_key_cache = Hash.new { |h, k| h[k] = platform_authorized_key(k) }.compare_by_identity
          @platform_resolve_type_key_cache = Hash.new { |h, k| h[k] = platform_resolve_type_key(k) }.compare_by_identity
          @platform_source_key_cache = Hash.new { |h, source_cls| h[k] = platform_source_class_key(source_cls) }.compare_by_identity
        end

        def instrument(keyword, payload, &block)
          raise "Implement #{self.class}#instrument to measure the block"
        end

        def start_event(keyword, payload)
          ev = self.class::Event.new(self, keyword, payload)
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

        class Event
          def initialize(engine, keyword, payload)
            @engine = engine
            @keyword = keyword
            @payload = payload
          end

          attr_reader :keyword, :payload

          def start
            raise "Implement #{self.class}#start to begin a new event (#{inspect})"
          end

          def finish
            raise "Implement #{self.class}#finish to end this event (#{inspect})"
          end
        end
      end

      class DryMonitorEngine < Engine
        EVENT_NAMES = {
          execute_field: "execute_field.graphql",
          dataloader_source: "dataloader_source.graphql",
          authorized: "authorized.graphql",
          resolve_type: "resolve_type.graphql",
          execute: "execute.graphql",
          parse: "parse.graphql",
          validate: "validate.graphql",
          analyze: "analyze.graphql",
          lex: "lex.graphql",
        }.compare_by_identity

        def instrument(keyword, payload, &block)
          name = EVENT_NAMES.fetch(keyword)
          Dry::Monitor.instrument(name, payload, &block)
        end

        class Event < NotificationsTrace::Engine::Event
          def start
            @name = EVENT_NAMES.fetch(@keyword)
            Dry::Monitor.start(@name, @payload)
          end

          def finish
            Dry::Monitor.stop(@name, @payload)
          end
        end
      end

      # @param engine [Class<Engine>] The notifications engine to use -- other modules often provide a default here
      # @param set_transaction_name [Boolean] If `true`, use the GraphQL operation name as the request name on the monitoring platform
      # @param trace_scalars [Boolean] If `true`, leaf fields will be traced too (Scalars _and_ Enums)
      def initialize(engine:, set_transaction_name: false, trace_scalars: false, **rest)
        if defined?(Dry::Monitor) && engine == Dry::Monitor
          # Backwards compat
          engine = DryMonitoringEngine
        end

        @trace_scalars = trace_scalars
        @notifications_engine = engine.new(set_transaction_name: set_transaction_name)
        super
      end

      def parse(query_string:)
        @notifications_engine.instrument(:parse, query_string) do
          super
        end
      end

      def lex(query_string:)
        @notifications_engine.instrument(:lex, query_string) do
          super
        end
      end

      def validate(query:, validate:)
        @notifications_engine.instrument(:validate, query) do
          super
        end
      end

      def begin_analyze_multiplex(multiplex, analyzers)
        begin_notifications_event(:analyze)
        super
      end

      def end_analyze_multiplex(multiplex, analyzers)
        finish_notifications_event
        super
      end

      def execute_multiplex(multiplex:)
        @notifications_engine.instrument(:execute, multiplex) do
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
        begin_notifications_event(prev_ev.keyword, prev_ev.payload)
        super
      end

      def begin_authorized(type, object, context)
        begin_notifications_event(:authorized, type)
        super
      end

      def end_authorized(type, object, context, result)
        finish_notifications_event
        super
      end

      def begin_resolve_type(type, value, context)
        begin_notifications_event(:resolve_type, type)
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

      def begin_notifications_event(keyword, payload = nil, set_current: true)
        ev = @notifications_engine.start_event(keyword, payload)
        if set_current
          Fiber[CURRENT_EV_KEY] = ev
        end
        ev
      end

      def finish_notifications_event(ev = nil)
        finish_ev = ev || Fiber[CURRENT_EV_KEY]
        if finish_ev
          finish_ev.finish
          if ev.nil?
            Fiber.current.storage.delete(CURRENT_EV_KEY)
          end
        end
        finish_ev
      end
    end
  end
end
