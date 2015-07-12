GraphQL::InputFieldsField = GraphQL::Field.new do |f|
  f.name 'inputFields'
  f.description 'fields on this input object'
  f.type GraphQL::ListType.new(of_type: GraphQL::InputValueType)
  f.resolve lambda  { |target, _a, _c|
    if target.kind == GraphQL::TypeKinds::INPUT_OBJECT
      target.input_fields.values
    end
  }
end
