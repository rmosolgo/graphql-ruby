class GraphQL::Enum
  include GraphQL::NonNullWithBang
  extend GraphQL::Definable
  attr_definable :name, :description
  attr_reader :values
  def initialize
    @values = {}
    yield(self, GraphQL::TypeDefiner.instance, GraphQL::FieldDefiner.instance, GraphQL::ArgumentDefiner.instance)
  end

  def value(name, description=nil, deprecation_reason: nil, value: name)
    @values[name] = EnumValue.new(name: name, description: description, deprecation_reason: deprecation_reason, value: value)
  end

  def kind
    GraphQL::TypeKinds::ENUM
  end

  def coerce(value_name)
    @values[value_name].value
  end

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
