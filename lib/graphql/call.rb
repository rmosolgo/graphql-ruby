class GraphQL::Call
  attr_reader :name, :lambda
  def initialize(name:, lambda:)
    @name = name
    @lambda = lambda
  end
end