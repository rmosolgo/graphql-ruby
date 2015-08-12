GraphQL::Introspection::EnumValueType = GraphQL::ObjectType.define do
  name "__EnumValue"
  description "A possible value for an Enum"
  field :name, !types.String
  field :description, types.String
  field :deprecationReason, types.String, property: :deprecation_reason
  field :isDeprecated, !types.Boolean do
    resolve -> (obj, a, c) { !!obj.deprecation_reason }
  end
end
