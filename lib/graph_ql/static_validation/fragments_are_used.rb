class GraphQL::StaticValidation::FragmentsAreUsed
  def validate(context)
    v = context.visitor
    used_fragment_names = []
    defined_fragment_names = []
    v[GraphQL::Nodes::FragmentSpread] << -> (node) { used_fragment_names <<  node.name }
    v[GraphQL::Nodes::FragmentDefinition] << -> (node) { defined_fragment_names << node.name}
    v[GraphQL::Nodes::Document].leave << -> (node) { add_errors(context.errors, used_fragment_names, defined_fragment_names) }
  end

  private

  def add_errors(errors, used_fragment_names, defined_fragment_names)
    undefined_fragment_names = used_fragment_names - defined_fragment_names
    if undefined_fragment_names.any?
      errors << "Some fragments were used but not defined: #{undefined_fragment_names.join(", ")}"
    end

    unused_fragment_names = defined_fragment_names - used_fragment_names
    if unused_fragment_names.any?
      errors << "Some fragments were defined but not used: #{unused_fragment_names.join(", ")}"
    end
  end
end
