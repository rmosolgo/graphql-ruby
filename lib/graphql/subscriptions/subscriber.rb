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

      def initialize(schema:, store:, transports:)
        @schema = schema
        @store = store
        @transports = transports
      end

      def_delegators :@store, :register, :delete, :each_subscription

      # Fetch subscription matching this field + arguments pair
      # and evaluate them with `object` as underlying value.
      #
      # Results will be sent to the transport specified by the store.
      #
      # TODO handle raised errors during loading & delivering.
      # Subscription deliveries should be isolated.
      def trigger(event, args, object)
        event_key = Subscriptions::Event.serialize(event, args)
        @store.each_subscription(event_key) do |query_data|
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
          channel = query_data.fetch(:channel)
          transport = @transports.fetch(transport_key)
          transport.deliver(channel, result, query.context)
        end
      end
    end
  end
end
