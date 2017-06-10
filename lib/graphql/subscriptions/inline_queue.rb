# frozen_string_literal: true
module GraphQL
  module Subscriptions
    # Run the query right away and push it over transport right away.
    # This is the default if you don't provide a queue.
    # @api private
    module InlineQueue
      module_function
      # @param subscriber [GraphQL::Subscriptions::Subscriber]
      # @param channel [String]
      # @param event_key [String]
      # @param object [Object]
      # @return [void]
      def enqueue(subscriber, channel, event_key, object)
        subscriber.process(channel, event_key, object)
      end
    end
  end
end
