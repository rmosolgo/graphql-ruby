class GraphQL::StringType < GraphQL::ScalarType
  type_name "String"
  def coerce(value)
    value.to_s
  end
end
