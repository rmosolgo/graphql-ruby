GraphQL::FieldsField = GraphQL::Field.new do |f|
  f.description "List of fields on this object"
  f.type -> { GraphQL::ListType.new(of_type: GraphQL::NonNullType.new(of_type: GraphQL::FieldType)) }
  f.arguments({
    includeDeprecated: {type: GraphQL::BOOLEAN_TYPE, default_value: false}
  })
  f.resolve -> (object, arguments, context) {
    fields = object.fields.values
    if !arguments["includeDeprecated"]
      fields = fields.select {|f| !f.deprecation_reason }
    end
    fields
  }
end
