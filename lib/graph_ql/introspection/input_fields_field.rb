GraphQL::Introspection::InputFieldsField = GraphQL::Field.new do |f, type|
  f.name "inputFields"
  f.description "fields on this input object"
  f.type type[GraphQL::Introspection::InputValueType]
  f.resolve -> (target, a, c) {
    if target.kind.input_object?
      target.input_fields.values
    else
      nil
    end
  }
end
