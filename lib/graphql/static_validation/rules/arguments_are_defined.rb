class GraphQL::StaticValidation::ArgumentsAreDefined < GraphQL::StaticValidation::ArgumentsValidator
  def validate_node(parent, node, defn, context)
    argument_defn = defn.arguments[node.name]
    if argument_defn.nil?
      context.errors << message("#{parent.class.name.split("::").last} '#{parent.name}' doesn't accept argument #{node.name}", parent)
      GraphQL::Language::Visitor::SKIP
    else
      nil
    end
  end
end
