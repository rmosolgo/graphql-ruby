class GraphQL::StaticValidation::VariableDefaultValuesAreCorrectlyTyped
  include GraphQL::StaticValidation::Message::MessageHelper

  def validate(context)
    literal_validator = GraphQL::StaticValidation::LiteralValidator.new
    context.visitor[GraphQL::Nodes::Variable] << -> (node, parent) {
      if !node.default_value.nil?
        validate_default_value(node, literal_validator, context)
      end
    }
  end

  def validate_default_value(node, literal_validator, context)
    value = node.default_value
    if node.type.is_a?(GraphQL::Nodes::NonNullType)
      context.errors << message("Non-null variable $#{node.name} can't have a default value", node)
    else
      type = context.schema.types[node.type.name]
      if !literal_validator.validate(value, type)
        context.errors << message("Default value for $#{node.name} doesn't match type #{node.type.name}", node)
      end
    end
  end
end
