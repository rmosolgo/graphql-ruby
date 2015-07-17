GraphQL::INT_TYPE = GraphQL::ScalarType.new do |t|
  t.name "Int"
  def t.coerce(value)
    value.is_a?(Numeric) ? value.to_i : nil
  end
end
