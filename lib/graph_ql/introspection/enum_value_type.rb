GraphQL::Introspection::EnumValueType = GraphQL::ObjectType.new do |t, type, field|
  t.name "__EnumValue"
  t.description "A possible value for an Enum"
  t.fields({
    name:               field.build(type: !type.String),
    description:        field.build(type: !type.String),
    deprecationReason:  field.build(type: !type.String, property: :deprecation_reason),
    isDeprecated: GraphQL::Field.new { |f|
      f.type !type.Boolean
      f.resolve -> (obj, a, c) { !!obj.deprecation_reason }
    },
  })
end
