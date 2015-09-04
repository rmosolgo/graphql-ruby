GraphQL::Introspection::InputFieldsField = GraphQL::Field.define do
  name "inputFields"
  description "fields on this input object"
  type types[GraphQL::Introspection::InputValueType]
  resolve -> (target, a, c) {
    if target.kind.input_object?
      target.input_fields.values
    else
      nil
    end
  }
end
