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

  def input_fields=(new_fields)
    @input_fields = GraphQL::DefinitionHelpers::StringNamedHash.new(new_fields).to_h
  end

  def kind
    GraphQL::TypeKinds::INPUT_OBJECT
  end

  def coerce_input(value)
    input_values = {}
    input_fields.each do |input_key, input_field_defn|
      raw_value = value.fetch(input_key, input_field_defn.default_value)
      field_type = input_field_defn.type
      input_values[input_key] = field_type.coerce_input!(raw_value)
    end
    GraphQL::Query::Arguments.new(input_values)
  end
end
