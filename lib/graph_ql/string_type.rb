GraphQL::STRING_TYPE = GraphQL::ScalarType.define do
  name "String"
  coerce -> (value) { value.to_s }
end
