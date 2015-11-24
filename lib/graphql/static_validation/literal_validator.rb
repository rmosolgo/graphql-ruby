# Test whether `ast_value` is a valid input for `type`
class GraphQL::StaticValidation::LiteralValidator
  def validate(ast_value, type)
    if type.kind.non_null?
      (!ast_value.nil?) && validate(ast_value, type.of_type)
    elsif type.kind.list? && ast_value.is_a?(Array)
      item_type = type.of_type
      ast_value.all? { |val| validate(val, item_type) }
    elsif type.kind.scalar? && !ast_value.is_a?(GraphQL::Language::Nodes::AbstractNode) && !ast_value.is_a?(Array)
      type.valid_input?(ast_value)
    elsif type.kind.enum? && ast_value.is_a?(GraphQL::Language::Nodes::Enum)
      type.valid_input?(ast_value.name)
    elsif type.kind.input_object? && ast_value.is_a?(GraphQL::Language::Nodes::InputObject)
      required_input_fields_are_present(type, ast_value) &&
        present_input_field_values_are_valid(type, ast_value)
    elsif ast_value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
      true
    else
      false
    end
  end


  private


  def required_input_fields_are_present(type, ast_node)
    required_field_names = type.input_fields
      .values
      .select { |f| f.type.kind.non_null? }
      .map(&:name)
    present_field_names = ast_node.pairs.map(&:name)
    missing_required_field_names = required_field_names - present_field_names
    missing_required_field_names.none?
  end

  def present_input_field_values_are_valid(type, ast_node)
    fields = type.input_fields
    ast_node.pairs.all? do |value|
     field_type = fields[value.name].type
     validate(value.value, field_type)
   end
 end
end
