# frozen_string_literal: true
require "graphql/subscriptions/event"
require "graphql/subscriptions/instrumentation"
require "graphql/subscriptions/subscriber"

module GraphQL
  # A plugin for attaching subscription behavior to the schema
  # @example
  #   MySchema = GraphQL::Schema.define do
  #     use GraphQL::Subscriptions,
  #       store: MyDatabaseStorage.new,
  #       transports: {
  #         "apns" => ApnsTransport.new,
  #         "websocket" => WebsocketTransport.new,
  #       }
  #  end
  module Subscriptions
    module_function
    # Accept some application objects:
    # - `store` for registering subscription state
    # - named `transpors` for delivering payload
    #
    # Apply special behavior to subscription root fields with instrumentation.
    #
    # Prepare `MySchema.subscriber` for receiving triggers from the application.
    #
    # @param store [<#register(query, events), #each_subscription(event_key, &block)>]
    # @param transports [Hash<String => <#deliver(channel, result, ctx)>]
    def use(defn, store:, transports:)
      schema = defn.target
      schema.subscriber = Subscriptions::Subscriber.new(
        schema: schema,
        store: store,
        transports: transports,
      )
      instrumentation = Subscriptions::Instrumentation.new(
        schema: schema,
        subscriber: schema.subscriber,
      )
      defn.instrument(:field, instrumentation)
      defn.instrument(:query, instrumentation)
      nil
    end
  end
end
