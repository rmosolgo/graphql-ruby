# frozen_string_literal: true
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

  class Argument
    include GraphQL::Define::InstanceDefinable
    accepts_definitions :name, :type, :description, :default_value, :as
    attr_accessor :type, :description, :default_value, :name, :as

    ensure_defined(:name, :description, :default_value, :type=, :type, :as)

    def default_value?
      !!@has_default_value
    end

    def default_value=(new_default_value)
      @has_default_value = true
      @default_value = new_default_value
    end

    # @!attribute name
    #   @return [String] The name of this argument on its {GraphQL::Field} or {GraphQL::InputObjectType}

    # @param new_input_type [GraphQL::BaseType, Proc] Assign a new input type for this argument (if it's a proc, it will be called after schema initialization)
    def type=(new_input_type)
      @clean_type = nil
      @dirty_type = new_input_type
    end

    # @return [GraphQL::BaseType] the input type for this argument
    def type
      @clean_type ||= GraphQL::BaseType.resolve_related_type(@dirty_type)
    end
  end
end
