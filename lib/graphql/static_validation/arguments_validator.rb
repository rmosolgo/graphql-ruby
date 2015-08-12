# Implement validate_node
class GraphQL::StaticValidation::ArgumentsValidator
  include GraphQL::StaticValidation::Message::MessageHelper

  def validate(context)
    visitor = context.visitor
    visitor[GraphQL::Language::Nodes::Field] << -> (node, parent) {
      return if context.skip_field?(node.name)
      field_defn = context.field_definition
      validate_node(node, field_defn, context)
    }
    visitor[GraphQL::Language::Nodes::Directive] << -> (node, parent) {
      directive_defn = context.schema.directives[node.name]
      validate_node(node, directive_defn, context)
    }
  end
end
