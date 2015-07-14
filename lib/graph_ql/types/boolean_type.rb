GraphQL::BOOLEAN_TYPE = GraphQL::ScalarType.new do |t|
  t.name "Boolean"
  def t.coerce(value)
    !!value
  end
end
