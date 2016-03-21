GraphQL::Introspection::InputValueType = GraphQL::ObjectType.define do
  name "__InputValue"
  description "An input for a field or InputObject"
  field :name, !types.String, "The key for this value"
  field :description, types.String, "What this value is used for"
  field :type, -> { !GraphQL::Introspection::TypeType }, "The expected type for this value"
  field :defaultValue, types.String, "The value applied if no other value is provided" do
    resolve -> (obj, args, ctx) {
      value = obj.default_value
      if value.is_a?(String)
        "\"#{value}\""
      else
        value
      end
    }
  end
end
