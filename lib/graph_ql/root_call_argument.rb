# Created by {RootCall.argument}, used internally by GraphQL
class GraphQL::RootCallArgument
  attr_reader :type, :name, :any_number
  attr_accessor :index
  def initialize(type:, name:, any_number: false, index: nil)
    @type = type
    @name = name
    @any_number = any_number
    @index = index
  end
end