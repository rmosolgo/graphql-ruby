# frozen_string_literal: true
require "graphql/subscriptions/instrumentation"

module GraphQL
  module Subscriptions
    module_function

    def use(defn, subscriber_class:, options: {})
      schema = defn.target
      schema.subscriber = subscriber_class.new(options.merge(schema: schema))
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
