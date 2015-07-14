class GraphQL::StaticValidation::FieldsWillMerge
  HAS_SELECTIONS = [GraphQL::Nodes::OperationDefinition, GraphQL::Nodes::InlineFragment]

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
        field_errors = validate_field(field, name_to_field)
        errors.push(*field_errors)
        validate_selections(field.selections, name_to_field, fragments, errors)
      end
    end
  end

  def validate_field(field, name_to_field)
    name_in_selection = field.alias || field.name
    name_to_field[name_in_selection] ||= field
    first_field_def = name_to_field[name_in_selection]
    comparison = FieldDefinitionComparison.new(name_in_selection, first_field_def, field)
    comparison.errors
  end

  # Compare two field definitions, add errors to the list if there are any
  class FieldDefinitionComparison
    NAMED_VALUES = [GraphQL::Nodes::Enum, GraphQL::Nodes::VariableIdentifier]
    attr_reader :errors
    def initialize(name, prev_def, next_def)
      errors = []
      if prev_def.name != next_def.name
        errors << "Field '#{name}' has a field conflict: #{prev_def.name} or #{next_def.name}?"
      end
      prev_arguments = reduce_list(prev_def.arguments)
      next_arguments = reduce_list(next_def.arguments)
      if prev_arguments != next_arguments
        errors << "Field '#{name}' has an argument conflict: #{JSON.dump(prev_arguments)} or #{JSON.dump(next_arguments)}?"
      end
      prev_directive_names = prev_def.directives.map(&:name)
      next_directive_names = next_def.directives.map(&:name)
      if prev_directive_names != next_directive_names
        errors << "Field '#{name}' has a directive conflict: [#{prev_directive_names.join(", ")}] or [#{next_directive_names.join(", ")}]?"
      end
      prev_directive_args = prev_def.directives.map {|d| reduce_list(d.arguments) }
      next_directive_args = next_def.directives.map {|d| reduce_list(d.arguments) }
      if prev_directive_args != next_directive_args
        errors << "Field '#{name}' has a directive argument conflict: #{JSON.dump(prev_directive_args)} or #{JSON.dump(next_directive_args)}?"
      end
      @errors = errors
    end

    private

    # Turn AST tree into a hash
    # can't look up args, the names just have to match
    def reduce_list(args)
      args.reduce({}) do |memo, a|
        memo[a.name] = NAMED_VALUES.include?(a.value.class) ? a.value.name : a.value
        memo
      end
    end
  end
end
