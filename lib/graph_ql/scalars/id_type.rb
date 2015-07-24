GraphQL::ID_TYPE = GraphQL::ScalarType.new do |t|
  t.name "ID"
  def t.coerce(value)
    value.to_s
  end
end
