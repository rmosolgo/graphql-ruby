# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class SubscriptionRootExists
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        return if context.warden.root_type_for_operation("subscription")

        visitor = context.visitor

        visitor[GraphQL::Language::Nodes::OperationDefinition].enter << ->(ast_node, prev_ast_node) {
          if ast_node.operation_type == 'subscription'
            context.errors << message('Schema is not configured for subscriptions', ast_node, context: context)
            return GraphQL::Language::Visitor::SKIP
          end
        }
      end
    end
  end
end
