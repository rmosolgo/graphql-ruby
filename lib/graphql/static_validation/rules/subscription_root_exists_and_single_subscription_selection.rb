# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module SubscriptionRootExistsAndSingleSubscriptionSelection
      def on_operation_definition(node, parent)
        if node.operation_type == "subscription"
          if context.types.subscription_root.nil?
            add_error(GraphQL::StaticValidation::SubscriptionRootExistsError.new(
              'Schema is not configured for subscriptions',
              nodes: node
            ))
          elsif node.selections.size != 1
            add_error(GraphQL::StaticValidation::NotSingleSubscriptionError.new(
              'A subscription operation may only have one selection',
              nodes: node,
            ))
          else
            super
          end
        else
          super
        end
      end
    end
  end
end
