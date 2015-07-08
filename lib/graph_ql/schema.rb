class GraphQL::Schema
  extend ActiveSupport::Autoload
  autoload(:TypeReducer)

  attr_reader :query, :mutation
  def initialize(query:, mutation:)
    @query    = query
    @mutation = mutation
  end

  def types
    @types ||= begin
      types = {}
      TypeReducer.new(query, types)
      types
    end
  end
end
