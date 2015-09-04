class GraphQL::StaticValidation::ArgumentLiteralsAreCompatible < GraphQL::StaticValidation::ArgumentsValidator
  def validate_node(parent, node, defn, context)
    return if node.value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
    validator = GraphQL::StaticValidation::LiteralValidator.new
    arg_defn = defn.arguments[node.name]
    valid = validator.validate(node.value, arg_defn.type)
    if !valid
      context.errors << message("Argument #{node.name} on #{parent.class.name.split("::").last} '#{parent.name}' has an invalid value", parent)
    end
  end
end
