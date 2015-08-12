class GraphQL::StaticValidation::ArgumentsAreDefined < GraphQL::StaticValidation::ArgumentsValidator
  def validate_node(node, defn, context)
    skip = nil

    node.arguments.each do |argument|
      argument_defn = defn.arguments[argument.name]
      if argument_defn.nil?
        context.errors << message("#{node.class.name.split("::").last} '#{node.name}' doesn't accept argument #{argument.name}", node)
        skip = GraphQL::Language::Visitor::SKIP
      end
    end

    skip
  end
end
