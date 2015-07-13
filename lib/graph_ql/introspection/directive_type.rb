GraphQL::Introspection::DirectiveType = GraphQL::ObjectType.new do
  name "__Directive"
  description "A query directive in this schema"
  fields({
    name:         field(type: !type.String, desc: "The name of this directive"),
    description:  field(type: type.String, desc: "The description for this type"),
    args:         GraphQL::Introspection::ArgumentsField,
    onOperation:  field(type: !type.Boolean, property: :on_operation?, desc: "Does this directive apply to operations?"),
    onFragment:   field(type: !type.Boolean, property: :on_fragment?, desc: "Does this directive apply to fragments?"),
    onField:      field(type: !type.Boolean, property: :on_field?, desc: "Does this directive apply to fields?"),
  })
end
