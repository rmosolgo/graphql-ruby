module GraphQL
  module StaticValidation
    class FragmentTypesExist
      include GraphQL::StaticValidation::Message::MessageHelper

      FRAGMENTS_ON_TYPES = [
        GraphQL::Language::Nodes::FragmentDefinition,
        GraphQL::Language::Nodes::InlineFragment,
      ]

      def validate(context)
        FRAGMENTS_ON_TYPES.each do |node_class|
          context.visitor[node_class] << -> (node, parent) { validate_type_exists(node, context) }
        end
      end

      private

      def validate_type_exists(node, context)
        return unless node.type
        type = context.schema.types.fetch(node.type, nil)
        if type.nil?
          context.errors << message("No such type #{node.type}, so it can't be a fragment condition", node)
          GraphQL::Language::Visitor::SKIP
        end
      end
    end
  end
end
