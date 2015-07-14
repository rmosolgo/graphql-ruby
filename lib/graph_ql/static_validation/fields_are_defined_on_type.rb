class GraphQL::StaticValidation::FieldsAreDefinedOnType
  # These are jumping-off points for infering types down the tree
  TYPE_INFERRENCE_ROOTS = [
    GraphQL::Nodes::OperationDefinition,
    GraphQL::Nodes::FragmentDefinition
  ]

  IS_FIELD = Proc.new {|f| f.is_a?(GraphQL::Nodes::Field) }

  def validate(context)
    visitor = context.visitor
    TYPE_INFERRENCE_ROOTS.each do |node_class|
      visitor[node_class] << -> (node){ validate_document_part(node, context) }
    end
  end

  private
  def validate_document_part(part, context)
    if part.is_a?(GraphQL::Nodes::FragmentDefinition)
      type = context.schema.types[part.type]
      validate_selections(type, part.selections, context)
    elsif part.is_a?(GraphQL::Nodes::OperationDefinition)
      type = context.schema.public_send(part.operation_type) # mutation root or query root
      validate_selections(type, part.selections, context)
    end
  end

  def validate_selections(type, selections, context)
    if type.kind.union? && selections.any?(&IS_FIELD)
      context.errors << "Selections can't be made directly on unions (see selections on #{type.name})"
      return
    end
    selections
      .select(&IS_FIELD)  # don't worry about fragments
      .each do |ast_field|
        field = type.fields[ast_field.name]
        if field.nil?
          context.errors << "Field '#{ast_field.name}' doesn't exist on type '#{type.name}'"
        else
          field_type = field.type.kind.unwrap(field.type)
          validate_selections(field_type, ast_field.selections, context)
        end
      end
  end
end
