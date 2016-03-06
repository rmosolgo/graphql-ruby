# A complex input type for a field argument.
#
# @example An input type with name and number
#   PlayerInput = GraphQL::InputObjectType.define do
#     name("Player")
#     input_field :name, !types.String
#     input_field :number, !types.Int
#   end
#
class GraphQL::InputObjectType < GraphQL::BaseType
  attr_accessor :name, :description, :input_fields
  defined_by_config :name, :description, :input_fields
  alias :arguments :input_fields

  def input_fields=(new_fields)
    @input_fields = GraphQL::DefinitionHelpers::StringNamedHash.new(new_fields).to_h
  end

  def kind
    GraphQL::TypeKinds::INPUT_OBJECT
  end

  def validate_non_null_input(input)
    fail ArgumentError.new("input must be enumerable") unless input.is_a?(Enumerable)

    result = GraphQL::Query::InputValidationResult.new

    # Items in the input that are unexpected
    input.reject { |name, value| input_fields[name] }.each do |name, value|
      result.add_problem("Field is not defined on #{self.name}", [name])
    end

    # Items in the input that are expected, but have invalid values
    invalid_fields = input_fields.map do |name, field|
      field_result = field.type.validate_input(input[name])
      result.merge_result!(name, field_result) unless field_result.is_valid?
    end

    result
  end

  def coerce_non_null_input(value)
    input_values = {}
    input_fields.each do |input_key, input_field_defn|
      field_value = value[input_key]
      field_value = input_field_defn.type.coerce_input(field_value)
      if field_value.nil?
        field_value = input_field_defn.default_value
      end
      input_values[input_key] = field_value unless field_value.nil?
    end
    GraphQL::Query::Arguments.new(input_values)
  end
end
