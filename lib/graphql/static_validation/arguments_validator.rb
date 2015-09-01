# Implement validate_node
class GraphQL::StaticValidation::ArgumentsValidator
  include GraphQL::StaticValidation::Message::MessageHelper

  def validate(context)
    visitor = context.visitor
    visitor[GraphQL::Language::Nodes::Argument] << -> (node, parent) {
      return if parent.is_a?(GraphQL::Language::Nodes::InputObject) || context.skip_field?(parent.name)
      if parent.is_a?(GraphQL::Language::Nodes::Directive)
        parent_defn = context.schema.directives[parent.name]
      else
        parent_defn = context.field_definition
      end
      validate_node(parent, node, parent_defn, context)
    }
  end
end
