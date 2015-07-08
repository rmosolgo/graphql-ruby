GraphQL::INTEGER_TYPE = GraphQL::ScalarType.new do
  name "Integer"
  def coerce(value)
    value.to_i
  end
end
