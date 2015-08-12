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
  attr_accessor :name, :type, :description, :default_value

  include GraphQL::DefinitionHelpers::DefinedByConfig

  # This object is `self` when you're defining arguments with a block.
  # @example `argument` helper's `self` is a DefinitionConfig
  #
  #   argument :name do
  #     puts self.class.name
  #   end
  #   # => GraphQL::Argument::DefinitionConfig
  #
  class DefinitionConfig
    extend GraphQL::DefinitionHelpers::Definable
    attr_definable :type, :description, :default_value, :name

    def to_instance
      GraphQL::Argument.new(
        type: type,
        description: description,
        default_value: default_value,
        name: name,
      )
    end
  end

  def initialize(type: nil, description: nil, default_value: nil, name: nil)
    @type = type
    @description = description,
    @default_value = default_value
    @name = name
  end
end
