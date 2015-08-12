GraphQL::Introspection::TypeType = GraphQL::ObjectType.define do
  name "__Type"
  description "A type in the GraphQL schema"

  field :name, !types.String,  "The name of this type"
  field :description, types.String, "What this type represents"

  field :kind do
    type GraphQL::Introspection::TypeKindEnum
    description "The kind of this type"
    resolve -> (target, a, c) { target.kind.name }
  end

  field :fields,          field: GraphQL::Introspection::FieldsField
  field :ofType,          field: GraphQL::Introspection::OfTypeField
  field :inputFields,     field: GraphQL::Introspection::InputFieldsField
  field :possibleTypes,   field: GraphQL::Introspection::PossibleTypesField
  field :enumValues,      field: GraphQL::Introspection::EnumValuesField
  field :interfaces,      field: GraphQL::Introspection::InterfacesField
end
