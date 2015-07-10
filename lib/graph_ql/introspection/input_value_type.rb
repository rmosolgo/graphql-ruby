GraphQL::InputValueType = GraphQL::ObjectType.new do
  name "InputValue"
  description "An input for a field or InputObject"
  fields({
    name:         field(type: !type.String, desc: "The key for this value"),
    description:  field(type: type.String, desc: "What this value is used for"),
    type:         field(type: -> { GraphQL::TypeType }, desc: "The expected type for this value"),
    defaultValue: field(type: type.String, property: :default_value, desc: "The value applied if no other value is provided")
  })
end
