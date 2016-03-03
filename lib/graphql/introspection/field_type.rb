GraphQL::Introspection::FieldType = GraphQL::ObjectType.define do
  name "__Field"
  description "Field on a GraphQL type"
  field :name, !types.String, "The name for accessing this field"
  field :description, types.String, "The description of this field"
  field :type, !GraphQL::Introspection::TypeType, "The return type of this field"
  field :isDeprecated, !types.Boolean, "Is this field deprecated?" do
    resolve -> (obj, a, c) { !!obj.deprecation_reason }
  end
  field :args, field: GraphQL::Introspection::ArgumentsField
  field :deprecationReason, types.String,  "Why this field was deprecated", property: :deprecation_reason
end
