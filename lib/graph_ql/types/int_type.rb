GraphQL::INT_TYPE = GraphQL::ScalarType.new do
  name "Int"
  def coerce(value)
    value.to_i
  end
end
