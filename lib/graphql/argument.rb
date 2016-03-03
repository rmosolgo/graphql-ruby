module GraphQL
  # Used for defined arguments ({Field}, {InputObjectType})
  #
  # {#name} must be a String.
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
  class Argument
    include GraphQL::Define::InstanceDefinable
    accepts_definitions :name, :type, :description, :default_value
    attr_accessor :type, :description, :default_value

    # @return [String] The name of this argument on its {GraphQL::Field} or {GraphQL::InputObjectType}
    attr_accessor :name
  end
end
