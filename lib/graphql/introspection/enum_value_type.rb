GraphQL::Introspection::EnumValueType = GraphQL::ObjectType.define do
  name "__EnumValue"
  description "One possible value for a given Enum. Enum values are unique values, not a "\
              "placeholder for a string or numeric value. However an Enum value is returned in "\
              "a JSON response as a string."
  field :name, !types.String
  field :description, types.String
  field :isDeprecated, !types.Boolean do
    resolve ->(obj, a, c) { !!obj.deprecation_reason }
  end
  field :deprecationReason, types.String, property: :deprecation_reason
end
