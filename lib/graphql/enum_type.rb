# A finite set of possible values, represented in query strings with
# SCREAMING_CASE_NAMES
#
# @example An enum of programming languages
#
#   LanguageEnum = GraphQL::EnumType.define do
#     name "Languages"
#     description "Programming languages for Web projects"
#     value("PYTHON", "A dynamic, function-oriented language")
#     value("RUBY", "A very dynamic language aimed at programmer happiness")
#     value("JAVASCRIPT", "Accidental lingua franca of the web")
#   end
class GraphQL::EnumType < GraphQL::BaseType
  attr_accessor :name, :description, :values
  defined_by_config :name, :description, :values

  def values=(values)
    @values_by_name = {}
    @values_by_value = {}
    values.each do |enum_value|
      @values_by_name[enum_value.name] = enum_value
      @values_by_value[enum_value.value] = enum_value
    end
  end

  def values
    @values_by_name
  end

  # Define a value within this enum
  # @deprecated use {.define} API instead
  # @param name [String] the string representation of this value
  # @param description [String]
  # @param deprecation_reason [String] if provided, `deprecated?` will be true
  # @param value [Object] the underlying value for this enum value
  def value(name, description=nil, deprecation_reason: nil, value: name)
    values[name] = EnumValue.new(name: name, description: description, deprecation_reason: deprecation_reason, value: value)
  end

  def kind
    GraphQL::TypeKinds::ENUM
  end

  def valid_non_null_input?(value_name)
    @values_by_name.key?(value_name)
  end

  # Get the underlying value for this enum value
  #
  # @example get episode value from Enum
  #   episode = EpisodeEnum.coerce("NEWHOPE")
  #   episode # => 6
  #
  # @param value_name [String] the string representation of this enum value
  # @return [Object] the underlying value for this enum value
  def coerce_non_null_input(value_name)
    @values_by_name.fetch(value_name).value
  end

  def coerce_result(value)
    @values_by_value.fetch(value).name
  end

  def to_s
    name
  end

  # A value within an {EnumType}
  #
  # Created with {EnumType#value}
  class EnumValue
    attr_reader :name, :description, :deprecation_reason, :value
    def initialize(name:, description:, deprecation_reason:, value:)
      @name = name
      @description = description
      @deprecation_reason = deprecation_reason
      @value = value
    end
  end
end
