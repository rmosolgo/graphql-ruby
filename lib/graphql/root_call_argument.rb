class GraphQL::RootCallArgument
  attr_reader :type, :name, :any_number
  def initialize(type:, name:, any_number: false)
    @type = type
    @name = name
    @any_number = any_number
  end
end