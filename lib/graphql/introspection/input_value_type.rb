# frozen_string_literal: true
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
      if obj.default_value?
        value = obj.default_value
        if value.nil?
          'null'
        else
          coerced_default_value = obj.type.coerce_result(value, ctx)
          if obj.type.unwrap.is_a?(GraphQL::EnumType)
            coerced_default_value
          else
            GraphQL::Language.serialize(coerced_default_value)
          end
        end
      else
        nil
      end
    }
  end
  introspection true
end
