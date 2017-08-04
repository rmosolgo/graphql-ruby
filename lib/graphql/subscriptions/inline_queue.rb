# frozen_string_literal: true
# test_via: ../subscriptions.rb
module GraphQL
  module Subscriptions
    # Run the query right away and push it over transport right away.
    # This is the default if you don't provide a queue.
    # @api private
    class InlineQueue
      def initialize(schema:, store:)
        @schema = schema
        @store = store
      end

      # @param schema [GraphQL::Schema]
      # @param channel [String]
      # @param event_key [String]
      # @param object [Object]
      # @return [void]
      def enqueue(channel, event_key, object)
        @schema.subscriber.process(channel, event_key, object)
      end

      # @param event [GraphQL::Subscriptions::Event]
      # @return [void]
      def enqueue_all(event, object)
        event_key = event.key
        @store.each_channel(event_key) do |channel|
          enqueue(channel, event_key, object)
        end
      end
    end
  end
end
