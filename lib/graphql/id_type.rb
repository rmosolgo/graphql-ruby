GraphQL::ID_TYPE = GraphQL::ScalarType.define do
  name "ID"
  coerce -> (value) { value.to_s }
end
