# Used for defined arguments ({Field}, {InputObjectType})
#
# Created by {ArgumentDefiner}
class GraphQL::Argument
  attr_reader :type, :description, :default_value
  attr_accessor :name

  include GraphQL::DefinitionHelpers::DefinedByConfig

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

  def initialize(type:, description: nil, default_value: nil, name: nil)
    @type = type
    @description = description,
    @default_value = default_value
    @name = name
  end
end
