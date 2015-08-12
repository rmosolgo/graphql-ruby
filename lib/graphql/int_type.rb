GraphQL::INT_TYPE = GraphQL::ScalarType.define do
  name "Int"
  coerce -> (value) { value.is_a?(Numeric) ? value.to_i : nil }
end
