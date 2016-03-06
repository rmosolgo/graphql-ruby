GraphQL::FLOAT_TYPE = GraphQL::ScalarType.define do
  name "Float"
  coerce -> (value) do
    value.is_a?(Numeric) ? value.to_f : nil
  end
end
