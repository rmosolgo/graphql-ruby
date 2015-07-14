GraphQL::INT_TYPE = GraphQL::ScalarType.new do |t|
  t.name "Int"
  def t.coerce(value)
    value.to_i
  end
end
