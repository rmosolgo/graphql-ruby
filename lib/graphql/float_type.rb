GraphQL::FLOAT_TYPE = GraphQL::ScalarType.define do
  name "Float"
  coerce_input -> (value) { value.is_a?(Numeric) ? value.to_f : nil }
  coerce_result -> (value) { value.to_f }
end
