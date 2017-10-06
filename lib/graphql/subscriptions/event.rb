# frozen_string_literal: true
# test_via: ../subscriptions.rb
module GraphQL
  class Subscriptions
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
      attr_reader :topic

      def initialize(name:, arguments:, field: nil, context: nil, scope: nil)
        @name = name
        @arguments = arguments
        @context = context
        field ||= context.field
        scope_val = scope || (context && field.subscription_scope && context[field.subscription_scope])

        @topic = self.class.serialize(name, arguments, field, scope: scope_val)
      end

      # @return [String] an identifier for this unit of subscription
      def self.serialize(name, arguments, field, scope:)
        normalized_args = case arguments
        when GraphQL::Query::Arguments
          arguments
        when Hash
          GraphQL::Query::LiteralInput.from_arguments(
            arguments,
            field,
            nil,
          )
        else
          raise ArgumentError, "Unexpected arguments: #{arguments}, must be Hash or GraphQL::Arguments"
        end

        sorted_h = normalized_args.to_h.sort.to_h
        JSON.dump([serialize_scope(scope), name, sorted_h])
      end

      # @return [String] an identifier for the subscription scope.
      def self.serialize_scope(scope)
        case
        when scope.is_a?(Array)
          scope.map { |s| serialize_scope(s) }.join(':')
        when scope.respond_to?(:to_gid_param)
          scope.to_gid_param
        when scope.respond_to?(:to_param)
          scope.to_param
        else
          scope.to_s
        end
      end
    end
  end
end
