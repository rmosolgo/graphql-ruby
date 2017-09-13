# frozen_string_literal: true
require "graphql/subscriptions/event"
require "graphql/subscriptions/instrumentation"
if defined?(ActionCable)
  require "graphql/subscriptions/action_cable_subscriptions"
end

module GraphQL
  class Subscriptions
    def self.use(defn, options = {})
      schema = defn.target
      options[:schema] = schema
      schema.subscriptions = self.new(options)
      instrumentation = Subscriptions::Instrumentation.new(schema: schema)
      defn.instrument(:field, instrumentation)
      defn.instrument(:query, instrumentation)
      nil
    end

    def initialize(kwargs)
      @schema = kwargs[:schema]
    end

    # Fetch subscriptions matching this field + arguments pair
    # And pass them off to the queue.
    # @param event_name [String]
    # @param args [Hash]
    # @param object [Object]
    # @param scope [Symbol, String]
    # @return [void]
    def trigger(event_name, args, object, scope: nil)
      field = @schema.get_field("Subscription", event_name)
      if !field
        raise "No subscription matching trigger: #{event_name}"
      end

      event = Subscriptions::Event.new(
        name: event_name,
        arguments: args,
        field: field,
        scope: scope,
      )
      execute_all(event, object)
    end

    def initialize(schema:, **rest)
      @schema = schema
    end

    # `event` was triggered on `object`, and `subscription_id` was subscribed,
    # so it should be updated.
    #
    # Load `subscription_id`'s GraphQL data, re-evaluate the query, and deliver the result.
    #
    # This is where a queue may be inserted to push updates in the background.
    #
    # @param subscription_id [String]
    # @param event [GraphQL::Subscriptions::Event] The event which was triggered
    # @param object [Object] The value for the subscription field
    # @return [void]
    def execute(subscription_id, event, object)
      # Lookup the saved data for this subscription
      query_data = read_subscription(subscription_id)
      # Fetch the required keys from the saved data
      query_string = query_data.fetch(:query_string)
      variables = query_data.fetch(:variables)
      context = query_data.fetch(:context)
      operation_name = query_data.fetch(:operation_name)
      # Re-evaluate the saved query
      result = @schema.execute(
        {
          query: query_string,
          context: context,
          subscription_topic: event.topic,
          operation_name: operation_name,
          variables: variables,
          root_value: object,
        }
      )
      deliver(subscription_id, result)
    end

    # Event `event` occurred on `object`,
    # Update all subscribers.
    # @param event [Subscriptions::Event]
    # @param object [Object]
    # @return [void]
    def execute_all(event, object)
      each_subscription_id(event) do |subscription_id|
        execute(subscription_id, event, object)
      end
    end

    # Get each `subscription_id` subscribed to `event.topic` and yield them
    # @param event [GraphQL::Subscriptions::Event]
    # @yieldparam subscription_id [String]
    # @return [void]
    def each_subscription_id(event)
      raise NotImplementedError
    end

    # The system wants to send an update to this subscription.
    # Read its data and return it.
    # @param subscription_id [String]
    # @return [Hash] Containing required keys
    def read_subscription(subscription_id)
      raise NotImplementedError
    end

    # A subscription query was re-evaluated, returning `result`.
    # The result should be send to `subscription_id`.
    # @param subscription_id [String]
    # @param result [Hash]
    # @param context [GraphQL::Query::Context]
    # @return [void]
    def deliver(subscription_id, result, context)
      raise NotImplementedError
    end

    # `query` was executed and found subscriptions to `events`.
    # Update the database to reflect this new state.
    # @param query [GraphQL::Query]
    # @param events [Array<GraphQL::Subscriptions::Event>]
    # @return [void]
    def write_subscription(query, events)
      raise NotImplementedError
    end
  end
end
