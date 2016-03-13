GraphQL::INT_TYPE = GraphQL::ScalarType.define do
  name "Int"
  coerce_input -> (value) { value.is_a?(Numeric) ? value.to_i : nil }
  coerce_result -> (value) { value.to_i }
end
