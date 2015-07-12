GraphQL::FieldType = GraphQL::ObjectType.new do
  name "__Field"
  description "Field on a GraphQL type"
  self.fields = {
    name: field(type: !type.String, desc: "The name for accessing this field"),
    description: field(type: !type.String, desc: "The description of this field"),
    type: field(type: !GraphQL::TypeType, desc: "The return type of this field"),
    isDeprecated: GraphQL::Field.new { |f|
      f.type !type.Boolean
      f.description "Is this field deprecated?"
      f.resolve -> (obj, a, c) { !!obj.deprecation_reason }
    },
    deprecationReason: field(type: type.String, property: :deprecation_reason, desc: "Why this field was deprecated"),
  }
end
