GraphQL::EnumValueType = GraphQL::ObjectType.new do
  name "__EnumValue"
  description "A possible value for an Enum"
  fields({
    name: field(type: !type.String),
    description: field(type: !type.String),
    deprecationReason: field(type: !type.String, property: :deprecation_reason),
    isDeprecated: field(type: !type.Boolean, property: :deprecated?),
  })
end
