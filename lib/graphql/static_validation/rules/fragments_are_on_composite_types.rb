# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class FragmentsAreOnCompositeTypes
      include GraphQL::StaticValidation::Message::MessageHelper

      HAS_TYPE_CONDITION = [
        GraphQL::Language::Nodes::FragmentDefinition,
        GraphQL::Language::Nodes::InlineFragment,
      ]

      def validate(context)
        HAS_TYPE_CONDITION.each do |node_class|
          context.visitor[node_class] << ->(node, parent) {
            validate_type_is_composite(node, context)
          }
        end
      end

      private

      def validate_type_is_composite(node, context)
        node_type = node.type
        if node_type.nil?
          # Inline fragment on the same type
        else
          type_name = node_type.to_query_string
          type_def = context.warden.get_type(type_name)
          if type_def.nil? || !type_def.kind.composite?
            context.errors <<  message("Invalid fragment on type #{type_name} (must be Union, Interface or Object)", node, context: context)
            GraphQL::Language::Visitor::SKIP
          end
        end
      end
    end
  end
end
