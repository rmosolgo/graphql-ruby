# frozen_string_literal: true
module GraphQL
  class Subscriptions
    class DefaultSubscriptionResolveExtension < GraphQL::Subscriptions::SubscriptionRoot::Extension
      def resolve(context:, object:, arguments:)
        has_override_implementation = @field.resolver ||
          object.respond_to?(@field.resolver_method)

        if !has_override_implementation
          if context.query.subscription_update?
            object.object
          else
            context.skip
          end
        else
          yield(object, arguments)
        end
      end
    end
  end
end
