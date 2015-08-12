GraphQL::FLOAT_TYPE = GraphQL::ScalarType.define do
  name "Float"
  coerce -> (value) do
    value.respond_to?(:to_f) ? value.to_f : nil
  end
end
