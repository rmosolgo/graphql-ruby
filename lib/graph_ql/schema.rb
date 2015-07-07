class GraphQL::Schema
  attr_reader :query, :mutation
  def initialize(query:, mutation:)
    @query    = query
    @mutation = mutation
  end
end
