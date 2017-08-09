# frozen_string_literal: true
require "graphql/subscriptions/event"
require "graphql/subscriptions/implementation"
require "graphql/subscriptions/instrumentation"

module GraphQL
  class Subscriptions
    attr_reader :implementation

    def self.use(defn, options = {})
      schema = defn.target
      options[:schema] = schema
      options[:implementation] ||= Subscriptions::Implementation
      schema.subscriber = self.new(options)
      instrumentation = Subscriptions::Instrumentation.new(schema: schema)
      defn.instrument(:field, instrumentation)
      defn.instrument(:query, instrumentation)
      nil
    end

    def initialize(kwargs)
      @schema = kwargs[:schema]
      implementation_class = kwargs.delete(:implementation)
      @implementation = implementation_class.new(kwargs)
    end

    # Fetch subscriptions matching this field + arguments pair
    # And pass them off to the queue.
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
      @implementation.enqueue_all(event, object)
    end
  end
end
