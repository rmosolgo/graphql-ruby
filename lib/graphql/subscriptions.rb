# frozen_string_literal: true
require "graphql/subscriptions/instrumentation"

module GraphQL
  module Subscriptions
    module_function

    def use(defn, subscriber:)
      schema = defn.target
      instrumentation = Subscriptions::Instrumentation.new(schema: schema, subscriber: subscriber)
      defn.instrument(:field, instrumentation)
      defn.instrument(:query, instrumentation)
      nil
    end
  end
end
