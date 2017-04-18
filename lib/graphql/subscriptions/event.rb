# frozen_string_literal: true
module GraphQL
  module Subscriptions
    # This thing can be:
    # - Subscribed to by `subscription { ... }`
    # - Triggered by `MySchema.subscriber.trigger(name, arguments, obj)`
    #
    # An array of `Event`s are passed to `store.register(query, events)`.
    class Event
      # @return [String] Corresponds to the Subscription root field name
      attr_reader :name

      # @return [GraphQL::Query::Arguments]
      attr_reader :arguments

      # @return [GraphQL::Query::Context]
      attr_reader :context

      # @return [String] An opaque string which identifies this event, derived from `name` and `arguments`
      attr_reader :key

      def initialize(name:, arguments:, context:)
        @name = name
        @arguments = arguments
        @context = context
        @key = self.class.serialize(name, arguments)
      end

      # @return [String] an identifier for this unit of subscription
      def self.serialize(name, arguments)
        "#{name}(#{JSON.dump(arguments.to_h)})"
      end
    end
  end
end
