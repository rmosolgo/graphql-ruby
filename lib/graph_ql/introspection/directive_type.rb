GraphQL::Introspection::DirectiveType = GraphQL::ObjectType.new do |t, type|
  t.name "__Directive"
  t.description "A query directive in this schema"
  t.fields({
    name:         t.field(type: !type.String, desc: "The name of this directive"),
    description:  t.field(type: type.String, desc: "The description for this type"),
    args:         GraphQL::Introspection::ArgumentsField,
    onOperation:  t.field(type: !type.Boolean, property: :on_operation?, desc: "Does this directive apply to operations?"),
    onFragment:   t.field(type: !type.Boolean, property: :on_fragment?, desc: "Does this directive apply to fragments?"),
    onField:      t.field(type: !type.Boolean, property: :on_field?, desc: "Does this directive apply to fields?"),
  })
end
