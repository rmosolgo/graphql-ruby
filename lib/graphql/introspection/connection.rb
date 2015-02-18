class GraphQL::Introspection::Connection < GraphQL::Connection
  field :count

  def count
    size
  end
end