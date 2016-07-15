GraphQL::STRING_TYPE = GraphQL::ScalarType.define do
  name "String"
  description "The `String` scalar type represents textual data, represented as UTF-8 character sequences. The String type is most often used by GraphQL to represent free-form human-readable text."

  coerce_result -> (value) { value.to_s }
  coerce_input -> (value) { value.is_a?(String) ? value : nil }
end
