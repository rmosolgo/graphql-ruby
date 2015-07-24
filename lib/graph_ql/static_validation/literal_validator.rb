# Test whether `ast_value` is a valid input for `type`
class GraphQL::StaticValidation::LiteralValidator
  def validate(ast_value, type)
    if type.kind.non_null?
      (!ast_value.nil?) && validate(ast_value, type.of_type)
    elsif type.kind.list? && ast_value.is_a?(Array)
      item_type = type.of_type
      ast_value.all? { |val| validate(val, item_type) }
    elsif type.kind.scalar?
      !type.coerce(ast_value).nil?
    elsif type.kind.enum? && ast_value.is_a?(GraphQL::Nodes::Enum)
      !type.coerce(ast_value.name).nil?
    elsif type.kind.input_object? && ast_value.is_a?(GraphQL::Nodes::InputObject)
      fields = type.input_fields
      ast_value.pairs.all? do |value|
        field_type = fields[value.name].type
        present_if_required = field_type.kind.non_null? ? !value.nil? : true
        present_if_required && validate(value.value, field_type)
      end
    else
      false
    end
  end
end
