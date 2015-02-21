class GraphQL::Introspection::Connection < GraphQL::Connection
  type :introspection_connection

  field.number(:count)

  def count
    size
  end
end