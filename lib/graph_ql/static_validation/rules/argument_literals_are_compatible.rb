class GraphQL::StaticValidation::ArgumentLiteralsAreCompatible < GraphQL::StaticValidation::ArgumentsValidator
  def validate_node(node, defn, context)
    args_with_literals = node.arguments.select {|a| !a.value.is_a?(GraphQL::Nodes::VariableIdentifier)}
    validator = GraphQL::StaticValidation::LiteralValidator.new
    args_with_literals.each do |arg|
      arg_defn = defn.arguments[arg.name]
      valid = validator.validate(arg.value, arg_defn.type)
      if !valid
        context.errors << message("#{arg.name} on #{node.class.name.split("::").last} '#{node.name}' has an invalid value", node)
      end
    end
  end
end
