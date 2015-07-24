class GraphQL::StaticValidation::FragmentTypesExist
  include GraphQL::StaticValidation::Message::MessageHelper

  FRAGMENTS_ON_TYPES = [
    GraphQL::Nodes::FragmentDefinition,
    GraphQL::Nodes::InlineFragment,
  ]

  def validate(context)
    FRAGMENTS_ON_TYPES.each do |node_class|
      context.visitor[node_class] << -> (node, parent) { validate_type_exists(node, context) }
    end
  end

  private

  def validate_type_exists(node, context)
    type = context.schema.types[node.type]
    if type.nil?
      context.errors << message("No such type #{node.type}, so it can't be a fragment condition", node)
      GraphQL::Visitor::SKIP
    end
  end
end
