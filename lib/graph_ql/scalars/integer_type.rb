GraphQL::INTEGER_TYPE = GraphQL::Type.new do
  type_name "Integer"
  def coerce(value)
    value.to_i
  end
end
