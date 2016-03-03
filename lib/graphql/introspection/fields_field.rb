GraphQL::Introspection::FieldsField = GraphQL::Field.define do
  description "List of fields on this object"
  type -> { types[!GraphQL::Introspection::FieldType] }
  argument :includeDeprecated, GraphQL::BOOLEAN_TYPE, default_value: false
  resolve -> (object, arguments, context) {
    return nil if !object.kind.fields?
    fields = object.all_fields
    if !arguments["includeDeprecated"]
      fields = fields.select {|f| !f.deprecation_reason }
    end
    fields.sort_by(&:name)
  }
end
