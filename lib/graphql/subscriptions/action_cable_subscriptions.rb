# frozen_string_literal: true
require "securerandom"

module GraphQL
  class Subscriptions
    # A subscriptions implementation that sends data
    # as ActionCable broadcastings.
    #
    # Experimental, some things to keep in mind:
    #
    # - No queueing system; ActiveJob should be added
    # - Take care to reload context when re-delivering the subscription. (see {Query#subscription_update?})
    #
    # @example Adding ActionCableSubscriptions to your schema
    #   MySchema = GraphQL::Schema.define do
    #     # ...
    #     use GraphQL::Subscriptions::ActionCableSubscriptions
    #   end
    #
    # @example Implementing a channel for GraphQL Subscriptions
    #   class GraphqlChannel < ApplicationCable::Channel
    #     def subscribed
    #       @subscription_ids = []
    #     end
    #
    #     def execute(data)
    #       query = data["query"]
    #       variables = ensure_hash(data["variables"])
    #       operation_name = data["operationName"]
    #       context = {
    #         current_user: current_user,
    #         # Make sure the channel is in the context
    #         channel: self,
    #       }
    #
    #       result = MySchema.execute({
    #         query: query,
    #         context: context,
    #         variables: variables,
    #         operation_name: operation_name
    #       })
    #
    #       payload = {
    #         result: result.to_h,
    #         more: result.subscription?,
    #       }
    #
    #       # Track the subscription here so we can remove it
    #       # on unsubscribe.
    #       if result.context[:subscription_id]
    #         @subscription_ids << context[:subscription_id]
    #       end
    #
    #       transmit(payload)
    #     end
    #
    #     def unsubscribed
    #       @subscription_ids.each { |sid|
    #         CardsSchema.subscriptions.delete_subscription(sid)
    #       }
    #     end
    #   end
    #
    class ActionCableSubscriptions < GraphQL::Subscriptions
      SUBSCRIPTION_PREFIX = "graphql-subscription:"
      EVENT_PREFIX = "graphql-event:"
      def initialize(**rest)
        # A per-process map of subscriptions to deliver.
        # This is provided by Rails, so let's use it
        @subscriptions = Concurrent::Map.new
        super
      end

      # An event was triggered; Push the data over ActionCable.
      # Subscribers will re-evaluate locally.
      # TODO: this method name is a smell
      def execute_all(event, object)
        ActionCable.server.broadcast(EVENT_PREFIX + event.topic, object)
      end

      # This subscription was re-evaluated.
      # Send it to the specific stream where this client was waiting.
      def deliver(subscription_id, result)
        payload = { result: result.to_h, more: true }
        ActionCable.server.broadcast(SUBSCRIPTION_PREFIX + subscription_id, payload)
      end

      # A query was run where these events were subscribed to.
      # Store them in memory in _this_ ActionCable frontend.
      # It will receive notifications when events come in
      # and re-evaluate the query locally.
      def write_subscription(query, events)
        channel = query.context[:channel]
        subscription_id = query.context[:subscription_id] ||= SecureRandom.uuid
        channel.stream_from(SUBSCRIPTION_PREFIX + subscription_id)
        @subscriptions[subscription_id] = query
        events.each do |event|
          channel.stream_from(EVENT_PREFIX + event.topic, coder: ActiveSupport::JSON) do |message|
            execute(subscription_id, event, message)
            nil
          end
        end
      end

      # Return the query from "storage" (in memory)
      def read_subscription(subscription_id)
        query = @subscriptions[subscription_id]
        {
          query_string: query.query_string,
          variables: query.provided_variables,
          context: query.context.to_h,
          operation_name: query.operation_name,
        }
      end

      # The channel was closed, forget about it.
      def delete_subscription(subscription_id)
        @subscriptions.delete(subscription_id)
      end
    end
  end
end
