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
    result = GraphQL::Query::InputValidationResult.new

    # Items in the input that are unexpected
    input.each do |name, value|
      if input_fields[name].nil?
        result.add_problem("Field is not defined on #{self.name}", [name])
      end
    end

    # Items in the input that are expected, but have invalid values
    invalid_fields = input_fields.map do |name, field|
      field_result = field.type.validate_input(input[name])
      if !field_result.valid?
        result.merge_result!(name, field_result)
      end
    end

    result
  end

  def coerce_non_null_input(value)
    input_values = {}

    input_fields.each do |input_key, input_field_defn|
      field_value = value[input_key]
      field_value = input_field_defn.type.coerce_input(field_value)

      # Try getting the default value
      if field_value.nil?
        field_value = input_field_defn.default_value
      end

      if !field_value.nil?
        input_values[input_key] = field_value
      end
    end

    GraphQL::Query::Arguments.new(input_values)
  end
end
