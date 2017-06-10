# frozen_string_literal: true
module GraphQL
  module Subscriptions
    module SchemaExecute
      # @param subscriber [GraphQL::Subscriptions::Subscriber]
      # @param channel [String]
      # @param object [Object]
      # @return [void]
      def self.call(subscriber, channel, event_key, object)
        # Lookup the saved data for this subscription
        query_data = subscriber.get(channel)
        # Fetch the required keys from the saved data
        query_string = query_data.fetch(:query_string)
        variables = query_data.fetch(:variables)
        context = query_data.fetch(:context)
        operation_name = query_data.fetch(:operation_name)

        # Re-evaluate the saved query
        query = GraphQL::Query.new(
          subscriber.schema,
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

        # Find the transport for this subscription
        transport_key = query_data.fetch(:transport)
        transport = subscriber.transports.fetch(transport_key)
        # Deliver the payload over the transport
        transport.deliver(channel, result, query.context)
      end
    end
  end
end
