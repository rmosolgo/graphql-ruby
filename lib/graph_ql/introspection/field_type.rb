GraphQL::Introspection::FieldType = GraphQL::ObjectType.new do |t, type|
  t.name "__Field"
  t.description "Field on a GraphQL type"
  t.fields = {
    name: t.field(type: !type.String, desc: "The name for accessing this field"),
    description: t.field(type: !type.String, desc: "The description of this field"),
    type: t.field(type: !GraphQL::Introspection::TypeType, desc: "The return type of this field"),
    isDeprecated: GraphQL::Field.new { |f|
      f.type !type.Boolean
      f.description "Is this field deprecated?"
      f.resolve -> (obj, a, c) { !!obj.deprecation_reason }
    },
    deprecationReason: t.field(type: type.String, property: :deprecation_reason, desc: "Why this field was deprecated"),
  }
end
