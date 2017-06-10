# frozen_string_literal: true
module GraphQL
  module Subscriptions
    # Hang along with the schema and:
    #
    # - Coordinate access to the application-provided store
    # - Receive `trigger`s from the application
    # - Respond to them by:
    #   - loading data from the store
    #   - evaluating the subscription
    #   - sending the result over the specified application-provided transport
    class Subscriber
      extend GraphQL::Delegate

      attr_reader :store, :queue, :transports, :schema
      def initialize(schema:, store:, queue: InlineQueue, execute: SchemaExecute, transports:)
        @schema = schema
        @store = store
        @queue = queue
        @transports = transports
        @execute = execute
      end

      def_delegators :@store, :set, :get, :delete, :each_channel

      # Fetch subscriptions matching this field + arguments pair
      # And pass them off to the queue.
      def trigger(event, args, object)
        event_key = Subscriptions::Event.serialize(event, args)
        @store.each_channel(event_key) do |channel|
          @queue.enqueue(@schema, channel, event_key, object)
        end
      end

      # TODO rename this.
      # It runs the query and delivers it.
      # It's probably called in a background job,
      # but the default is inline.
      def process(channel, event_key, object)
        @execute.call(self, channel, event_key, object)
      end
    end
  end
end
