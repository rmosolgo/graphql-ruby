class GraphQL::Introspection::FieldsConnection < GraphQL::Connection
  field :count

  def count
    items.size
  end
end