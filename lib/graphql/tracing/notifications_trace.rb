# frozen_string_literal: true

require "graphql/tracing/platform_trace"

module GraphQL
  module Tracing
    # This implementation forwards events to a notification handler (i.e.
    # ActiveSupport::Notifications or Dry::Monitor::Notifications)
    # with a `graphql` suffix.
    module NotificationsTrace
      # Initialize a new NotificationsTracing instance
      #
      # @param engine [#instrument(key, metadata, block)] The notifications engine to use
      def initialize(engine:, **rest)
        @notifications_engine = engine
        @notifications_analyze_event = nil
        super
      end

      def parse(query_string:)
        @notifications_engine.instrument("parse.graphql", query_string: query_string) do
          super
        end
      end

      def lex(query_string:)
        @notifications_engine.instrument("lex.graphql", query_string: query_string) do
          super
        end
      end

      def validate(query:, validate:)
        @notifications_engine.instrument("validate.graphql", validate: validate, query: query) do
          super
        end
      end

      def begin_analyze_multiplex(multiplex, analyzers)
        begin_notifications_event("analyze.graphql", EmptyObjects::EMPTY_HASH)
        super
      end

      def end_analyze_multiplex(multiplex, analyzers)
        finish_notifications_event
        super
      end

      def execute_multiplex(multiplex:)
        @notifications_engine.instrument("execute.graphql", multiplex: multiplex) do
          super
        end
      end

      def begin_execute_field(field, object, arguments, query)
        begin_notifications_event("execute_field.graphql", EmptyObjects::EMPTY_HASH)
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
        begin_notifications_event(prev_ev.name, prev_ev.payload)
        super
      end

      def begin_authorized(type, object, context)
        begin_notifications_event("authorized.graphql", EmptyObjects::EMPTY_HASH)
        super
      end

      def end_authorized(type, object, context, result)
        finish_notifications_event
        super
      end

      def begin_resolve_type(type, value, context)
        begin_notifications_event("resolve_type.graphql", EmptyObjects::EMPTY_HASH)
        super
      end

      def end_resolve_type(type, value, context, resolved_type)
        finish_notifications_event
        super
      end

      CURRENT_EV_KEY = :__notifications_graphql_trace_event
      PREVIOUS_EV_KEY = :__notifications_graphql_trace_previous_event
      private

      def begin_notifications_event(name, payload, set_current: true)
        ev = @notifications_engine.new_event(name, payload)
        ev.start!
        if set_current
          Fiber[CURRENT_EV_KEY] = ev
        end
        ev
      end

      def finish_notifications_event(ev = nil)
        finish_ev = ev || Fiber[CURRENT_EV_KEY]
        if finish_ev
          finish_ev.finish!
          @notifications_engine.publish_event(finish_ev)
          if ev.nil?
            Fiber.current.storage.delete(CURRENT_EV_KEY)
          end
        end
        finish_ev
      end
    end
  end
end
