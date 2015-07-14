class GraphQL::StaticValidation::FieldsAreDefinedOnType
  include GraphQL::StaticValidation::Message::MessageHelper
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
      validate_selections(type, part, context)
    elsif part.is_a?(GraphQL::Nodes::OperationDefinition)
      type = context.schema.public_send(part.operation_type) # mutation root or query root
      validate_selections(type, part, context)
    end
  end

  def validate_selections(type, parent, context)
    selections = parent.selections
    if type.kind.union? && selections.any?(&IS_FIELD)
      context.errors << message("Selections can't be made directly on unions (see selections on #{type.name})", parent)
      return
    end
    selections
      .select(&IS_FIELD)  # don't worry about fragments
      .each do |ast_field|
        field = type.fields[ast_field.name]
        if field.nil?
          context.errors << message("Field '#{ast_field.name}' doesn't exist on type '#{type.name}'", parent)
        else
          field_type = field.type.kind.unwrap(field.type)
          validate_selections(field_type, ast_field, context)
        end
      end
  end
end
