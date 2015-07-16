GraphQL::Introspection::InputValueType = GraphQL::ObjectType.new do |t, type, field|
  t.name "InputValue"
  t.description "An input for a field or InputObject"
  t.fields({
    name:         field.build(type: !type.String, desc: "The key for this value"),
    description:  field.build(type: type.String, desc: "What this value is used for"),
    type:         field.build(type: -> { GraphQL::Introspection::TypeType }, desc: "The expected type for this value"),
    defaultValue: field.build(type: type.String, property: :default_value, desc: "The value applied if no other value is provided")
  })
end
