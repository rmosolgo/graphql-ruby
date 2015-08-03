class GraphQL::Enum
  include GraphQL::DefinitionHelpers::NonNullWithBang
  extend GraphQL::DefinitionHelpers::Definable
  attr_definable :name, :description
  attr_reader :values
  def initialize
    @values = {}
    yield(
      self,
      GraphQL::DefinitionHelpers::TypeDefiner.instance,
      GraphQL::DefinitionHelpers::FieldDefiner.instance,
      GraphQL::DefinitionHelpers::ArgumentDefiner.instance
    )
  end

  # Define a value within this enum
  #
  # @param name [String] the string representation of this value
  # @param description [String]
  # @param deprecation_reason [String] if provided, `deprecated?` will be true
  # @param value [Object] the underlying value for this enum value
  def value(name, description=nil, deprecation_reason: nil, value: name)
    @values[name] = EnumValue.new(name: name, description: description, deprecation_reason: deprecation_reason, value: value)
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
    @values[value_name].value
  end

  # A value within an {Enum}
  #
  # Created with {Enum#value}
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
