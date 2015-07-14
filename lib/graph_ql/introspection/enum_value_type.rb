GraphQL::Introspection::EnumValueType = GraphQL::ObjectType.new do |t,type|
  t.name "__EnumValue"
  t.description "A possible value for an Enum"
  t.fields({
    name: t.field(type: !type.String),
    description: t.field(type: !type.String),
    deprecationReason: t.field(type: !type.String, property: :deprecation_reason),
    isDeprecated: GraphQL::Field.new { |f|
      f.type !type.Boolean
      f.resolve -> (obj, a, c) { !!obj.deprecation_reason }
    },
  })
end
