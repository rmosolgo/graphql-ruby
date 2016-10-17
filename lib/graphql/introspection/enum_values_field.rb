GraphQL::Introspection::EnumValuesField = GraphQL::Field.define do
  type types[!GraphQL::Introspection::EnumValueType]
  argument :includeDeprecated, types.Boolean, default_value: false
  resolve ->(object, arguments, context) do
    return nil if !object.kind.enum?
    fields = object.values.values
    if !arguments["includeDeprecated"]
      fields = fields.select {|f| !f.deprecation_reason }
    end
    fields
  end
end
