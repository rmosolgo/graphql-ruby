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
      extend Forwardable

      def initialize(schema:, store:, queue: InlineQueue, transports:)
        @schema = schema
        @store = store
        @queue = queue
        @transports = transports
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
        query_data = @store.get(channel)
        query_string = query_data.fetch(:query_string)
        variables = query_data.fetch(:variables)
        context = query_data.fetch(:context)
        operation_name = query_data.fetch(:operation_name)

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

        transport_key = query_data.fetch(:transport)
        transport = @transports.fetch(transport_key)
        transport.deliver(channel, result, query.context)
      end
    end
  end
end
