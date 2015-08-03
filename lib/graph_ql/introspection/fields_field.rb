GraphQL::Introspection::FieldsField = GraphQL::Field.new do |f, type, field, arg|
  f.description "List of fields on this object"
  f.type -> { type[!GraphQL::Introspection::FieldType] }
  f.arguments({
    includeDeprecated: arg.build({type: GraphQL::BOOLEAN_TYPE, default_value: false})
  })
  f.resolve -> (object, arguments, context) {
    return nil if !object.kind.fields?
    fields = object.fields.values
    if !arguments["includeDeprecated"]
      fields = fields.select {|f| !f.deprecation_reason }
    end
    fields
  }
end
