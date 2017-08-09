# frozen_string_literal: true
# test_via: ../subscriptions.rb
module GraphQL
  class Subscriptions
    class Implementation
      def initialize(schema:, **rest)
        @schema = schema
      end

      def execute(channel, event_key, object)
        # Lookup the saved data for this subscription
        query_data = get_subscription(channel)
        # Fetch the required keys from the saved data
        query_string = query_data.fetch(:query_string)
        variables = query_data.fetch(:variables)
        context = query_data.fetch(:context)
        operation_name = query_data.fetch(:operation_name)

        # Re-evaluate the saved query
        query = GraphQL::Query.new(
          @schema,
          query_string,
          {
            context: context,
            subscription_key: event_key,
            operation_name: operation_name,
            variables: variables,
            root_value: object,
          }
        )
        result = query.result

        deliver(channel, result, query.context)
      end

      # Event `event` occurred on `object`,
      # Update all subscribers.
      # @param event [Subscriptions::Event]
      # @param object [Object]
      def enqueue_all(event, object)
        event_key = event.key
        each_channel(event_key) do |channel|
          enqueue(channel, event_key, object)
        end
      end

      def enqueue(channel, event_key, object)
        execute(channel, event_key, object)
      end

      # Get each channel subscribed to `event_key` and yield them
      # @param event_key [String]
      # @yieldparam channel [String]
      # @return [void]
      def each_channel(event_key)
        raise NotImplementedError
      end

      def get_subscription(channel)
        raise NotImplementedError
      end

      # Deliver the payload to the channel
      def deliver(channel, result, context)
        raise NotImplementedError
      end

      def subscribed(query, events)
        raise NotImplementedError
      end
    end
  end
end
