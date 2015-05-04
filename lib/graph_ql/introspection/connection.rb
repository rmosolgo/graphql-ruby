class GraphQL::Introspection::Connection < GraphQL::Connection
  type :introspection_connection

  field.number(:count, "The number of items")

  def count
    size
  end
end