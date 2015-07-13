GraphQL::Introspection::TypeType = GraphQL::ObjectType.new do
  name "__Type"
  description "A type in the GraphQL schema"

  self.fields = {
    name: field(type: !type.String, desc: "The name of this type"),
    kind: GraphQL::Field.new { |f|
      f.type GraphQL::Introspection::TypeKindEnum
      f.description "The kind of this type"
      f.resolve -> (target, a, c) { target.kind.name }
    },
    description: field(type: type.String, desc: "The description for this type"),
    fields: GraphQL::Introspection::FieldsField,
    ofType: GraphQL::Introspection::OfTypeField,
    inputFields: GraphQL::Introspection::InputFieldsField,
    possibleTypes: GraphQL::Introspection::PossibleTypesField,
    enumValues: GraphQL::Introspection::EnumValuesField
  }
end
# type __Type {
#   # OBJECT only
#   interfaces: [__Type!]
