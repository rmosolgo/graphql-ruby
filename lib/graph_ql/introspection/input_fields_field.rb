GraphQL::InputFieldsField = GraphQL::Field.new do |f|
  f.name "inputFields"
  f.description "fields on this input object"
  f.type GraphQL::ListType.new(of_type: GraphQL::InputValueType)
  f.resolve -> (target, a, c) {
    if target.kind.input_object?
      target.input_fields.values
    else
      nil
    end
  }
end
