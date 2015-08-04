GraphQL::FLOAT_TYPE = GraphQL::ScalarType.new do |t|
  t.name "Float"
  def t.coerce(value)
    value.respond_to?(:to_f) ? value.to_f : nil
  end
end
