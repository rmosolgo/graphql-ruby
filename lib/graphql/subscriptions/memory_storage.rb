# frozen_string_literal: true
require "securerandom"

module GraphQL
  class Subscriptions
    class MemoryStorage
      def initialize(*args)
        super
        # TODO thread-safety
        @event_subscriber_ids = Hash.new { |h,k| h[k] = [] }
        @subscribers_by_id = {}
      end

      def each_subscription_id(event)
        @event_subscriber_ids.each { |sub_id| yield(sub_id) }
      end

      def read_subscription(subscription_id)
        @subscribers_by_id[subscription_id]
      end

      def write_subscription(query, events)
        subscription_id = query.context[:subscription_id] ||= SecureRandom.uuid
        @subscribers_by_id[subscription_id] = query
        events.each do |event|
          @event_subscriber_ids[event.key] << subscription_ids
        end
      end
    end
  end
end
