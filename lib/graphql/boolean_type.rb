GraphQL::BOOLEAN_TYPE = GraphQL::ScalarType.define do
  # Everything else is nil
  ALLOWED_INPUTS = [true, false]

  name "Boolean"
  description "Represents `true` or `false` values."

  coerce_input -> (value) { ALLOWED_INPUTS.include?(value) ? value : nil }
  coerce_result -> (value) { !!value }
end
