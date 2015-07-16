class GraphQL::Enum
  include GraphQL::NonNullWithBang
  extend GraphQL::Definable
  attr_definable :name, :description
  attr_reader :values
  def initialize
    @values = {}
    yield(self, GraphQL::TypeDefiner.instance, GraphQL::FieldDefiner.instance, GraphQL::ArgumentDefiner.instance)
  end

  def value(name, description=nil, deprecation_reason: nil)
    @values[name] = EnumValue.new(name: name, description: description, deprecation_reason: deprecation_reason)
  end

  def kind
    GraphQL::TypeKinds::ENUM
  end

  class EnumValue
    attr_reader :name, :description, :deprecation_reason
    def initialize(name:, description:, deprecation_reason:)
      @name = name
      @description = description
      @deprecation_reason = deprecation_reason
    end
  end
end
