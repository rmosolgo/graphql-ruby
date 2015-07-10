GraphQL::BOOLEAN_TYPE = GraphQL::ScalarType.new do
  name "Boolean"
  def coerce(value)
    !!value
  end
end
