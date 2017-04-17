# frozen_string_literal: true
module GraphQL
  module Subscriptions
    class Subscriber
      extend Forwardable

      def initialize(schema:, store:, transports:)
        @schema = schema
        @store = store
        @transports = transports
      end

      def_delegators :@store, :register, :each_subscription

      def trigger(event, args, object)
        event_key = Subscriptions::Event.serialize(event, args)
        @store.each_subscription(event_key) do |query_data|
          query_string = query_data.fetch(:query_string)
          variables = query_data.fetch(:variables)
          context = query_data.fetch(:context)
          operation_name = query_data.fetch(:operation_name)

          result = @schema.execute(query_string, {
            context: context,
            subscription_name: event,
            operation_name: operation_name,
            variables: variables,
            root_value: object,
          })

          transport_key = query_data.fetch(:transport)
          channel = query_data.fetch(:channel)
          transport = @transports.fetch(transport_key)
          transport.deliver(channel, result)
        end
      end

      private

      def serialize_event(event, args)
        "#{event}(#{JSON.dump(args.to_h)})"
      end
    end
  end
end
