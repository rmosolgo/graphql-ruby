GraphQL::TypeType = GraphQL::ObjectType.new do
  name "__Type"
  description "A type in the GraphQL schema"

  self.fields = {
    name: field(type: !type.String, desc: "The name of this type"),
    kind: field(type: GraphQL::TypeKindEnum, desc: "The kind of this type"),
    description: field(type: type.String, desc: "The description for this type"),
    fields: GraphQL::FieldsField.new,
    ofType: GraphQL::OfTypeField,
    inputFields: GraphQL::InputFieldsField,
  }
end
# type __Type {
#   # OBJECT only
#   interfaces: [__Type!]
#
#   # INTERFACE and UNION only
#   possibleTypes: [__Type!]
#
#   # ENUM only
#   enumValues(includeDeprecated: Boolean = false): [__EnumValue!]
#
#   # INPUT_OBJECT only
#   inputFields: [__InputValue!]
# }
