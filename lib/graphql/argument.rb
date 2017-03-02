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

    ensure_defined(:name, :description, :default_value, :type=, :type, :as, :expose_as)

    def initialize_copy(other)
      @expose_as = nil
    end

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

    # @return [String] The name of this argument inside `resolve` functions
    def expose_as
      @expose_as ||= (@as || @name).to_s
    end

    NO_DEFAULT_VALUE = Object.new
    # @api private
    def self.from_dsl(name, type = nil, description = nil, default_value: NO_DEFAULT_VALUE, as: nil, &block)
      argument = if block_given?
        GraphQL::Argument.define(&block)
      else
        GraphQL::Argument.new
      end

      argument.name = name.to_s
      type && argument.type = type
      description && argument.description = description
      if default_value != NO_DEFAULT_VALUE
        argument.default_value = default_value
      end
      argument.as = as


      argument
    end
  end
end
