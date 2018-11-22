# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module SubscriptionRootExists
      def on_operation_definition(node, _parent)
        if node.operation_type == "subscription" && context.warden.root_type_for_operation("subscription").nil?
          add_error('Schema is not configured for subscriptions', node, extensions: {
            "rule": "StaticValidation::SubscriptionRootExists"
          })
        else
          super
        end
      end
    end
  end
end
