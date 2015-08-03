GraphQL::Introspection::FieldType = GraphQL::ObjectType.new do |t, type, field|
  t.name "__Field"
  t.description "Field on a GraphQL type"
  t.fields({
    name:         field.build(type: !type.String, desc: "The name for accessing this field"),
    description:  field.build(type: !type.String, desc: "The description of this field"),
    type:         field.build(type: !GraphQL::Introspection::TypeType, desc: "The return type of this field"),
    isDeprecated: GraphQL::Field.new { |f|
      f.type !type.Boolean
      f.description "Is this field deprecated?"
      f.resolve -> (obj, a, c) { !!obj.deprecation_reason }
    },
    args:  GraphQL::Introspection::ArgumentsField,
    deprecationReason: field.build(type: type.String, property: :deprecation_reason, desc: "Why this field was deprecated"),
  })
end
