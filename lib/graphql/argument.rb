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
  # @example defining an argument for an {InputObjectType}
  #   GraphQL::InputObjectType.define do
  #     argument :newName, !types.String
  #   end
  #
  class Argument
    include GraphQL::Define::InstanceDefinable
    accepts_definitions :name, :type, :description, :default_value
    lazy_defined_attr_accessor :type, :description, :default_value

    # @return [String] The name of this argument on its {GraphQL::Field} or {GraphQL::InputObjectType}
    def name
      ensure_defined
      @name
    end

    attr_writer :name

    def type=(new_return_type)
      ensure_defined
      @clean_type = nil
      @dirty_type = new_return_type
    end

    # Get the return type for this field.
    def type
      @clean_type ||= begin
        ensure_defined
        GraphQL::BaseType.resolve_related_type(@dirty_type)
      end
    end
  end
end
