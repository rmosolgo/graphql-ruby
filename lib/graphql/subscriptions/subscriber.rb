# frozen_string_literal: true
# test_via: ../subscriptions.rb
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
    #
    # TODO:
    #  - add generator for installing
    #  - better api than `schema.subscriber`
    class Subscriber
      extend GraphQL::Delegate

      attr_reader :store, :queue, :transports, :schema
      def initialize(schema:, store:, queue: InlineQueue, execute: SchemaExecute, transports:)
        @schema = schema
        @store = store
        @queue = queue.new(schema: schema, store: store)
        @transports = transports
        @execute = execute
      end

      def_delegators :@store, :set, :get, :delete, :each_channel

      # Fetch subscriptions matching this field + arguments pair
      # And pass them off to the queue.
      def trigger(event_name, args, object, scope: nil)
        field = @schema.get_field("Subscription", event_name)
        if !field
          raise "No subscription matching trigger: #{event_name}"
        end

        event = Subscriptions::Event.new(
          name: event_name,
          arguments: args,
          field: field,
          scope: scope,
        )
        @queue.enqueue_all(event, object)
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
