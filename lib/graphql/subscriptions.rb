# frozen_string_literal: true
require "graphql/subscriptions/event"
require "graphql/subscriptions/instrumentation"
require "graphql/subscriptions/subscriber"

module GraphQL
  module Subscriptions
    module_function

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
