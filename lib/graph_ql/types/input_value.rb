class GraphQL::InputValue
  attr_reader :type, :description, :default_value
  attr_accessor :name
  def initialize(type:, description: nil, default_value: nil, name: nil)
    @type = type
    @description = description,
    @default_value = default_value
    @name = name
  end
end
