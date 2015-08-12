GraphQL::BOOLEAN_TYPE = GraphQL::ScalarType.define do
  name "Boolean"
  coerce -> (value) { !!value }
end
