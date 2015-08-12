class GraphQL::StaticValidation::RequiredArgumentsArePresent < GraphQL::StaticValidation::ArgumentsValidator
  def validate_node(node, defn, context)
    present_argument_names = node.arguments.map(&:name)
    required_argument_names = defn.arguments.values
      .select { |a| a.type.kind.non_null? }
      .map(&:name)

    missing_names = required_argument_names - present_argument_names
    if missing_names.any?
      context.errors << message("#{node.class.name.split("::").last} '#{node.name}' is missing required arguments: #{missing_names.join(", ")}", node)
    end
  end
end
