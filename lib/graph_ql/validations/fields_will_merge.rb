class GraphQL::Validations::FieldsWillMerge
  HAS_SELECTIONS = [GraphQL::Nodes::OperationDefinition, GraphQL::Nodes::InlineFragment]
  NAMED_VALUES = [GraphQL::Nodes::Enum, GraphQL::Nodes::VariableIdentifier]

  def validate(context)
    fragments = {}
    has_selections = []
    visitor = context.visitor
    HAS_SELECTIONS.each do |node_class|
      visitor[node_class] << -> (node) { has_selections << node }
    end
    visitor[GraphQL::Nodes::FragmentDefinition] << -> (node) { fragments[node.name] = node }
    visitor[GraphQL::Nodes::Document].leave << -> (node) {
      has_selections.each { |node| validate_selections(node.selections, {}, fragments, context.errors)}
    }
  end

  private

  def validate_selections(selections, name_to_field, fragments, errors)
    selections.each do |field|
      if field.is_a?(GraphQL::Nodes::InlineFragment)
        validate_selections(field.selections, name_to_field, fragments, errors)
      elsif field.is_a?(GraphQL::Nodes::FragmentSpread)
        fragment = fragments[field.name]
        validate_selections(fragment.selections, name_to_field, fragments, errors)
      else
        validate_field(field, name_to_field, errors)
        validate_selections(field.selections, name_to_field, fragments, errors)
      end
    end
  end

  def validate_field(field, name_to_field, errors)
    name_in_selection = field.alias || field.name
    name_to_field[name_in_selection] ||= [field.name, reduce_list(field.arguments), reduce_list(field.directives)]
    first_field_def = name_to_field[name_in_selection]
    first_field = first_field_def[0]
    first_arguments = first_field_def[1]
    first_directives = first_field_def[2]
    if first_field != field.name
      errors << "Field '#{name_in_selection}' has a conflict: #{first_field} or #{field.name}?"
    end
    these_arguments = reduce_list(field.arguments)
    if first_arguments != these_arguments
      errors << "Field '#{name_in_selection}' has an argument conflict: #{JSON.dump(first_arguments)} or #{JSON.dump(these_arguments)}?"
    end
    these_directives = reduce_list(field.directives)
    if first_directives != these_directives
      errors << "Field '#{name_in_selection}' has a directive conflict: #{JSON.dump(first_directives)} or #{JSON.dump(these_directives)}?"
    end
  end

  def reduce_list(args)
    args.reduce({}) do |memo, a|
      memo[a.name] = NAMED_VALUES.include?(a.value.class) ? a.value.name : a.value
      memo
    end
  end
end
