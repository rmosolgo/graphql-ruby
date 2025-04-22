# frozen_string_literal: true

module GraphQL
  module Tracing
    # This implementation forwards events to a notification handler
    # (i.e. ActiveSupport::Notifications or Dry::Monitor::Notifications) with a `graphql` suffix.
    #
    # @see ActiveSupportNotificationsTrace ActiveSupport::Notifications integration
    module NotificationsTrace
      # @api private
      class Adapter
        def instrument(keyword, payload, &block)
          raise "Implement #{self.class}#instrument to measure the block"
        end

        def start_event(keyword, payload)
          ev = self.class::Event.new(keyword, payload)
          ev.start
          ev
        end

        class Event
          def initialize(name, payload)
            @name = name
            @payload = payload
          end

          attr_reader :name, :payload

          def start
            raise "Implement #{self.class}#start to begin a new event (#{inspect})"
          end

          def finish
            raise "Implement #{self.class}#finish to end this event (#{inspect})"
          end
        end
      end

      # @api private
      class DryMonitorAdapter < Adapter
        def instrument(...)
          Dry::Monitor.instrument(...)
        end

        class Event < Adapter::Event
          def start
            Dry::Monitor.start(@name, @payload)
          end

          def finish
            Dry::Monitor.stop(@name, @payload)
          end
        end
      end

      # @api private
      class ActiveSupportNotificationsAdapter < Adapter
        def instrument(...)
          ActiveSupport::Notifications.instrument(...)
        end

        class Event < Adapter::Event
          def start
            @asn_event = ActiveSupport::Notifications.instrumenter.new_event(@name, @payload)
            @asn_event.start!
          end

          def finish
            @asn_event.finish!
            ActiveSupport::Notifications.publish_event(@asn_event)
          end
        end
      end

      # @param engine [Class] The notifications engine to use, eg `Dry::Monitor` or `ActiveSupport::Notifications`
      def initialize(engine:, **rest)
        adapter = if defined?(Dry::Monitor) && engine == Dry::Monitor
          DryMonitoringAdapter
        elsif defined?(ActiveSupport::Notifications) && engine == ActiveSupport::Notifications
          ActiveSupportNotificationsAdapter
        else
          engine
        end
        @notifications = adapter.new
        super
      end

      def parse(**payload)
        @notifications.instrument("parse.graphql", payload) do
          super
        end
      end

      def lex(**payload)
        @notifications.instrument("lex.graphql", payload) do
          super
        end
      end

      def validate(**payload)
        @notifications.instrument("validate.graphql", payload) do
          super
        end
      end

      def begin_analyze_multiplex(multiplex, analyzers)
        begin_notifications_event("analyze.graphql", {multiplex: multiplex, analyzers: analyzers})
        super
      end

      def end_analyze_multiplex(_multiplex, _analyzers)
        finish_notifications_event
        super
      end

      def execute_multiplex(**payload)
        @notifications.instrument("execute.graphql", payload) do
          super
        end
      end

      def begin_execute_field(field, object, arguments, query)
        begin_notifications_event("execute_field.graphql", {field: field, object: object, arguments: arguments, query: query})
        super
      end

      def end_execute_field(_field, _object, _arguments, _query, _result)
        finish_notifications_event
        super
      end

      def dataloader_fiber_yield(source)
        Fiber[PREVIOUS_EV_KEY] = finish_notifications_event
        super
      end

      def dataloader_fiber_resume(source)
        prev_ev = Fiber[PREVIOUS_EV_KEY]
        if prev_ev
          begin_notifications_event(prev_ev.name, prev_ev.payload)
        end
        super
      end

      def begin_authorized(type, object, context)
        begin_notifications_event("authorized.graphql", {type: type, object: object, context: context})
        super
      end

      def end_authorized(type, object, context, result)
        finish_notifications_event
        super
      end

      def begin_resolve_type(type, object, context)
        begin_notifications_event("resolve_type.graphql", {type: type, object: object, context: context})
        super
      end

      def end_resolve_type(type, object, context, resolved_type)
        finish_notifications_event
        super
      end

      def begin_dataloader_source(source)
        begin_notifications_event("dataloader_source.graphql", { source: source })
        super
      end

      def end_dataloader_source(source)
        finish_notifications_event
        super
      end

      CURRENT_EV_KEY = :__notifications_graphql_trace_event
      PREVIOUS_EV_KEY = :__notifications_graphql_trace_previous_event

      private

      def begin_notifications_event(name, payload)
        Fiber[CURRENT_EV_KEY] = @notifications.start_event(name, payload)
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
