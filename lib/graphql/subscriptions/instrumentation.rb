# frozen_string_literal: true
module GraphQL
  module Subscriptions
    class Instrumentation
      def initialize(schema:, subscriber:)
        @subscriber = subscriber
        @schema = schema
      end

      def instrument(type, field)
        if type == @schema.subscription
          # This is a root field of `subscription`
          subscribing_resolve_proc = SubscriptionRegistrationResolve.new(field.resolve_proc)
          field.redefine(resolve: subscribing_resolve_proc)
        else
          field
        end
      end

      def before_query(query)
        # It's a subscription, but it's not an update:
        if query.subscription? && !query.subscription_name
          query.context[:subscriber] = @subscriber
          @subscriber.register_query(query)
        end
      end

      def after_query(query)
      end

      private

      class SubscriptionRegistrationResolve
        def initialize(inner_proc)
          @inner_proc = inner_proc
        end

        # Wrap the proc with subscription registration logic
        def call(obj, args, ctx)
          subscriber = ctx[:subscriber]
          if subscriber
            # `Subscriber#register` has some side-effects to register the subscription
            subscriber.register(obj, args, ctx)
            nil
          elsif ctx.field.name == ctx.query.subscription_name
            # The root object is _already_ the subscription update:
            obj
          else
            nil
          end
        end
      end
    end
  end
end
