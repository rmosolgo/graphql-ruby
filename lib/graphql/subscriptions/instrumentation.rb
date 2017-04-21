# frozen_string_literal: true
module GraphQL
  module Subscriptions
    # Wrap the root fields of the subscription type with special logic for:
    # - Registering the subscription during the first execution
    # - Evaluating the triggered portion(s) of the subscription during later execution
    class Instrumentation
      def initialize(schema:, subscriber:)
        @subscriber = subscriber
        @schema = schema
      end

      def instrument(type, field)
        if type == @schema.subscription
          # This is a root field of `subscription`
          subscribing_resolve_proc = SubscriptionRegistrationResolve.new(field.resolve_proc)
          field.redefine(resolve: subscribing_resolve_proc)
        else
          field
        end
      end

      # If needed, prepare to gather events which this query subscribes to
      def before_query(query)
        if query.subscription? && !query.subscription_update?
          query.context[:events] = []
        end
      end

      # After checking the root fields, pass the gathered events to the store
      def after_query(query)
        events = query.context[:events]
        if events && events.any?
          @subscriber.set(query, events)
        end
      end

      private

      class SubscriptionRegistrationResolve
        def initialize(inner_proc)
          @inner_proc = inner_proc
        end

        # Wrap the proc with subscription registration logic
        def call(obj, args, ctx)
          events = ctx[:events]
          if events
            # This is the first execution, so gather an Event
            # for the backend to register:
            events << Subscriptions::Event.new(
              name: ctx.field.name,
              arguments: args,
              context: ctx,
            )
            nil
          elsif ctx.irep_node.subscription_key == ctx.query.subscription_key
            # The root object is _already_ the subscription update:
            obj
          else
            # This is a subscription update, but this event wasn't triggered.
            ctx.skip
          end
        end
      end
    end
  end
end
