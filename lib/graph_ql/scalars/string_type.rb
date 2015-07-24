GraphQL::STRING_TYPE = GraphQL::ScalarType.new do |t|
  t.name "String"
  def t.coerce(value)
    value.to_s
  end
end
