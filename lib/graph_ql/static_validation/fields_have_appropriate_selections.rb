# Scalars _can't_ have selections
# Objects _must_ have selections
class GraphQL::StaticValidation::FieldsHaveAppropriateSelections
  include GraphQL::StaticValidation::Message::MessageHelper

  def validate(context)
    context.visitor[GraphQL::Nodes::Field] << -> (node, parent)  {
      field_defn = context.field_definition
      validate_field_selections(node, field_defn, context.errors)
    }
  end

  private

  def validate_field_selections(ast_field, field_defn, errors)
    resolved_type = field_defn.type.kind.unwrap(field_defn.type)
    if resolved_type.kind.scalar? && ast_field.selections.any?
      errors << message("Selections can't be made on scalars (field '#{ast_field.name}' returns #{resolved_type.name} but has selections [#{ast_field.selections.map(&:name).join(", ")}])", ast_field)
      return GraphQL::Visitor::SKIP
    elsif resolved_type.kind.object? && ast_field.selections.none?
      errors << message("Objects must have selections (field '#{ast_field.name}' returns #{resolved_type.name} but has no selections)", ast_field)
      return GraphQL::Visitor::SKIP
    end
  end
end
