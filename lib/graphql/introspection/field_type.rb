GraphQL::Introspection::FieldType = GraphQL::ObjectType.define do
  name "__Field"
  description "Object and Interface types are described by a list of Fields, each of which has "\
              "a name, potentially a list of arguments, and a return type."
  field :name, !types.String
  field :description, types.String
  field :args, GraphQL::Introspection::ArgumentsField
  field :type, !GraphQL::Introspection::TypeType
  field :isDeprecated, !types.Boolean do
    resolve ->(obj, a, c) { !!obj.deprecation_reason }
  end
  field :deprecationReason, types.String, property: :deprecation_reason
end
