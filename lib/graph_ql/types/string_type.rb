GraphQL::STRING_TYPE = GraphQL::ScalarType.new do
  name "String"
  def coerce(value)
    value.to_s
  end
end
