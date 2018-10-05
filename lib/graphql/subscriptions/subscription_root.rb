# frozen_string_literal: true

module GraphQL
  class Subscriptions
    # Extend this module in your subscription root when using {GraphQL::Execution::Interpreter}.
    module SubscriptionRoot
      def field(*args, extensions: [], **rest, &block)
        extensions += [Extension]
        super(*args, extensions: extensions, **rest, &block)
      end

      class Extension < GraphQL::Schema::FieldExtension
        def after_resolve(value:, context:, object:, arguments:, **rest)
          if value.is_a?(GraphQL::ExecutionError)
            value
          elsif (events = context.namespace(:subscriptions)[:events])
            # This is the first execution, so gather an Event
            # for the backend to register:
            events << Subscriptions::Event.new(
              name: field.name,
              arguments: arguments,
              context: context,
              field: field,
            )
            context.skip
          elsif context.query.subscription_topic == (subscription_topic = Subscriptions::Event.serialize(
              field.name,
              arguments,
              field,
              scope: (field.subscription_scope ? context[field.subscription_scope] : nil),
            ))
            # The root object is _already_ the subscription update,
            # it was passed to `.trigger`
            object.object
          else
            # This is a subscription update, but this event wasn't triggered.
            context.skip
          end
        end
      end
    end
  end
end
