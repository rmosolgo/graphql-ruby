# Used for defined arguments ({Field}, {InputObjectType})
#
# @example defining an argument for a field
#   GraphQL::Field.define do
#     # ...
#     argument :favoriteFood, types.String, "Favorite thing to eat", default_value: "pizza"
#   end
#
# @example defining an input field for an {InputObjectType}
#   GraphQL::InputObjectType.define do
#     input_field :newName, !types.String
#   end
#
class GraphQL::Argument
  include GraphQL::DefinitionHelpers::DefinedByConfig
  defined_by_config :name, :type, :description, :default_value
  attr_accessor :name, :type, :description, :default_value
end
