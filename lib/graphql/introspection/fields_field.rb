# frozen_string_literal: true
GraphQL::Introspection::FieldsField = GraphQL::Field.define do
  type -> { types[!GraphQL::Introspection::FieldType] }
  argument :includeDeprecated, GraphQL::BOOLEAN_TYPE, default_value: false
  resolve ->(object, arguments, context) {
    return nil if !object.kind.fields?
    fields = context.warden.fields(object)
    if !arguments["includeDeprecated"]
      fields = fields.select {|f| !f.deprecation_reason }
    end
    fields.sort_by(&:name)
  }
end
