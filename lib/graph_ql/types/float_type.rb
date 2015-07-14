GraphQL::FLOAT_TYPE = GraphQL::ScalarType.new do |t|
  t.name "Float"
  def t.coerce(value)
    value.to_f
  end
end
