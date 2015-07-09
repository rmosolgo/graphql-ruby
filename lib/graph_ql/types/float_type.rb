GraphQL::FLOAT_TYPE = GraphQL::ScalarType.new do
  name "Float"
  def coerce(value)
    value.to_f
  end
end
