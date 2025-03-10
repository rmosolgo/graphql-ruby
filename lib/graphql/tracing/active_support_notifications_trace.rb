# frozen_string_literal: true

require "graphql/tracing/notifications_trace"

module GraphQL
  module Tracing
    # This implementation forwards events to ActiveSupport::Notifications with a `graphql` suffix.
    #
    # @example Sending execution events to ActiveSupport::Notifications
    #   class MySchema < GraphQL::Schema
    #     trace_with(GraphQL::Tracing::ActiveSupportNotificationsTrace)
    #   end
    module ActiveSupportNotificationsTrace
      include NotificationsTrace

      class ActiveSupportNotificationsEngine < NotificationsTrace::Engine
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

        def instrument(keyword, data, &block)
          asn_name = EVENT_NAMES[keyword] || raise(ArgumentError, "No event name for #{key.inspect}")
          # TODO backwards compat for payload
          ActiveSupport::Notifications.instrument(asn_name, {}, &block)
        end

        class Event < NotificationsTrace::Engine::Event
          def start
            asn_name = EVENT_NAMES[keyword] || raise(ArgumentError, "No event name for #{key.inspect}")
            # TODO backwards compat for payload
            @asn_event = ActiveSupport::Notifications.instrumenter.new_event(asn_name, {})
            @asn_event.start!
          end

          def finish
            @asn_event.finish!
            ActiveSupport::Notifications.publish_event(@asn_event)
          end
        end
      end

      # @param trace_scalars [Boolean] Set to `true` for backwards compatibility
      def initialize(engine: ActiveSupportNotificationsEngine, trace_scalars: true, **rest)
        super
      end
    end
  end
end
