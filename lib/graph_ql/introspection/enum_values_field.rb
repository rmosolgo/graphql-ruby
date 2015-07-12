GraphQL::EnumValuesField = GraphQL::Field.new do |f|
  f.description "Values for this enum"
  f.type GraphQL::ListType.new(of_type: GraphQL::NonNullType.new(of_type: GraphQL::EnumValueType))
  f.arguments({
    includeDeprecated: {type: GraphQL::BOOLEAN_TYPE, default_value: false}
  })
  f.resolve -> (object, arguments, context) {
    return nil if !object.kind.enum?
    fields = object.values.values
    if !arguments["includeDeprecated"]
      fields = fields.select {|f| !f.deprecated? }
    end
    fields
  }
end
