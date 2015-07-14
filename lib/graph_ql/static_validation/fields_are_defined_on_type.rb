class GraphQL::StaticValidation::FieldsAreDefinedOnType
  TYPE_INFERRENCE_ROOTS = [GraphQL::Nodes::OperationDefinition, GraphQL::Nodes::FragmentDefinition]
  FIELD_MODIFIERS = [GraphQL::TypeKinds::LIST]

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
    selections
      .select {|f| f.is_a?(GraphQL::Nodes::Field) } # don't worry about fragments
      .each do |ast_field|
        field = type.fields[ast_field.name]
        if field.nil?
          context.errors << "Field '#{ast_field.name}' doesn't exist on type '#{type.name}'"
        else
          field_type = get_field_type(field)
          validate_selections(field_type, ast_field.selections, context)
        end
      end
  end

  def get_field_type(field)
    if FIELD_MODIFIERS.include?(field.type.kind)
      field.type.of_type
    else
      field.type
    end
  end
end
