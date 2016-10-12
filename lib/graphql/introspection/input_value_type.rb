GraphQL::Introspection::InputValueType = GraphQL::ObjectType.define do
  name "__InputValue"
  description "Arguments provided to Fields or Directives and the input fields of an "\
              "InputObject are represented as Input Values which describe their type and "\
              "optionally a default value."
  field :name, !types.String
  field :description, types.String
  field :type, !GraphQL::Introspection::TypeType
  field :defaultValue, types.String, "A GraphQL-formatted string representing the default value for this input value." do
    resolve ->(obj, args, ctx) {
      value = obj.default_value
      value.nil? ? nil : JSON.dump(obj.type.coerce_result(value))
    }
  end
end
