class GraphQL::Syntax::Query
  attr_reader :nodes, :variables, :fragments
  def initialize(nodes:, variables:, fragments:)
    @nodes = nodes
    @variables = variables
    @fragments = fragments
  end
end