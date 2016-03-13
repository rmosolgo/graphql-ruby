GraphQL::STRING_TYPE = GraphQL::ScalarType.define do
  name "String"
  coerce_result -> (value) { value.to_s }
  coerce_input -> (value) { value.is_a?(String) ? value : nil }
end
