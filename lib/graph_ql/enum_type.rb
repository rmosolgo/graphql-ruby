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
class GraphQL::EnumType
  include GraphQL::DefinitionHelpers::NonNullWithBang
  include GraphQL::DefinitionHelpers::DefinedByConfig
  extend GraphQL::DefinitionHelpers::Definable
  attr_definable :name, :description
  attr_accessor :values

  class DefinitionConfig
    extend GraphQL::DefinitionHelpers::Definable
    # These are deprecated:
    attr_definable :name, :description
    attr_reader :values
    def initialize
      @values = {}
    end

    def types
      GraphQL::DefinitionHelpers::TypeDefiner.instance
    end

    def value(name, desc = nil, deprecation_reason: nil, value: name)
      value = EnumValue.new(name: name, description: description, deprecation_reason: deprecation_reason, value: value)
      values[name] = value
    end

    def to_instance
      object = GraphQL::EnumType.new
      object.name = name
      object.description = description
      object.values = values
      object
    end
  end

  def initialize
    @values = {}
    if block_given?
      yield(
        self,
        GraphQL::DefinitionHelpers::TypeDefiner.instance,
        GraphQL::DefinitionHelpers::FieldDefiner.instance,
        GraphQL::DefinitionHelpers::ArgumentDefiner.instance
      )
      warn("Initializing with .new is deprecated, use .define instead! (see #{self})")
    end
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

  # Get the underlying value for this enum value
  #
  # @example get episode value from Enum
  #   episode = EpisodeEnum.coerce("NEWHOPE")
  #   episode # => 6
  #
  # @param value_name [String] the string representation of this enum value
  # @return [Object] the underlying value for this enum value
  def coerce(value_name)
    values[value_name].value
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
