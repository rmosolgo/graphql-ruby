# frozen_string_literal: true
module GraphQL
  class Subscriptions
    # Wrap the root fields of the subscription type with special logic for:
    # - Registering the subscription during the first execution
    # - Evaluating the triggered portion(s) of the subscription during later execution
    class Instrumentation
      def initialize(schema:)
        @schema = schema
      end

      # If needed, prepare to gather events which this query subscribes to
      def before_query(query)
        if query.subscription? && !query.subscription_update?
          query.context.namespace(:subscriptions)[:events] = []
        end
      end

      # After checking the root fields, pass the gathered events to the store
      def after_query(query)
        events = query.context.namespace(:subscriptions)[:events]
        if events && events.any?
          @schema.subscriptions.write_subscription(query, events)
        end
      end
    end
  end
end
