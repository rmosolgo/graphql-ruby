class GraphQL::Syntax::Query
  attr_reader :nodes, :variables
  def initialize(nodes:, variables:)
    @nodes = nodes
    @variables = variables
  end
end