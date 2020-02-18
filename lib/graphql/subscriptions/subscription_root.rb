# frozen_string_literal: true

module GraphQL
  class Subscriptions
    # Extend this module in your subscription root when using {GraphQL::Execution::Interpreter}.
    module SubscriptionRoot
      def self.extended(child_cls)
        child_cls.include(InstanceMethods)
      end

      # This is for maintaining backwards compatibility:
      # if a subscription field is created without a `subscription:` resolver class,
      # then implement the method with the previous default behavior.
      module InstanceMethods
        def skip_subscription_root(*)
          if context.query.subscription_update?
            object
          else
            context.skip
          end
        end
      end

      def field(*args, extensions: [], **rest, &block)
        extensions += [Extension]
        # Backwards-compat for schemas
        if !rest[:subscription]
          name = args.first
          alias_method(name, :skip_subscription_root)
        end
        super(*args, extensions: extensions, **rest, &block)
      end

      class Extension < GraphQL::Schema::FieldExtension
        def after_resolve(value:, context:, object:, arguments:, **rest)
          if value.is_a?(GraphQL::ExecutionError)
            value
          elsif (events = context.namespace(:subscriptions)[:events])
            # This is the first execution, so gather an Event
            # for the backend to register:
            event = Subscriptions::Event.new(
              name: field.name,
              arguments: arguments,
              context: context,
              field: field,
            )
            events << event
            value
          elsif context.query.subscription_topic == Subscriptions::Event.serialize(
              field.name,
              arguments,
              field,
              scope: (field.subscription_scope ? context[field.subscription_scope] : nil),
            )
            # This is a subscription update. The resolver returned `skip` if it should be skipped,
            # or else it returned an object to resolve the update.
            value
          else
            # This is a subscription update, but this event wasn't triggered.
            context.skip
          end
        end
      end
    end
  end
end
