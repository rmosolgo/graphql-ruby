GraphQL::TypeType = GraphQL::ObjectType.new do
  name "__Type"
  description "A type in the GraphQL schema"
  self.fields = {
    name: !field.string(:name, "The name of this type"),
    kind: !field(GraphQL::TypeKindEnum, :kind, "The kind of this type"),
  }
end
  # type __Type {
  #   kind: __TypeKind!
  #   name: String
  #   description: String
  #
  #   # OBJECT and INTERFACE only
  #   fields(includeDeprecated: Boolean = false): [__Field!]
  #
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
  #
  #   # NON_NULL and LIST only
  #   ofType: __Type
  # }
