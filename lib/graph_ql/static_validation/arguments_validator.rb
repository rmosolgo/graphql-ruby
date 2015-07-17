# Implement validate_node
class GraphQL::StaticValidation::ArgumentsValidator
  include GraphQL::StaticValidation::Message::MessageHelper

  def validate(context)
    visitor = context.visitor
    visitor[GraphQL::Nodes::Field] << -> (node, parent) {
      field_defn = context.field_definition
      validate_node(node, field_defn, context)
    }
    visitor[GraphQL::Nodes::Directive] << -> (node, parent) {
      directive_defn = context.schema.directives[node.name]
      validate_node(node, directive_defn, context)
    }
  end
end
