GraphQL::STRING_TYPE = GraphQL::Type.new do
  type_name "String"
  def coerce(value)
    value.to_s
  end
end
