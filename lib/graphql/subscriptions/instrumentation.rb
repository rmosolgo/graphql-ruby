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
        if query.subscription? && !query.subscription_update?
          query.context[:subscriptions] = []
        end
      end

      def after_query(query)
        subscriptions = query.context[:subscriptions]
        if subscriptions && subscriptions.any?
          @subscriber.register(query, subscriptions)
        end
      end

      private

      class SubscriptionRegistrationResolve
        def initialize(inner_proc)
          @inner_proc = inner_proc
        end

        # Wrap the proc with subscription registration logic
        def call(obj, args, ctx)
          subscriptions = ctx[:subscriptions]
          if subscriptions
            subscriptions << Subscriptions::Event.new(
              name: ctx.field.name,
              arguments: args,
              context: ctx,
            )
            nil
          elsif ctx.irep_node.subscription_key == ctx.query.subscription_key
            # The root object is _already_ the subscription update:
            obj
          else
            # It should only:
            # - Register the selection (first condition)
            # - Pass `obj` to the child selection (second condition)
            raise "An unselected subscription field should never be called"
          end
        end
      end
    end
  end
end
