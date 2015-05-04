class GraphQL::Introspection::FieldType < GraphQL::Node
  exposes "GraphQL::Field"
  desc "A property of a node"
  field.string(:name, "The identifier of this field")
  field.string(:type, "The type of this field")
  field.introspection_connection(:calls, "Calls that can be made on this field")

  def calls
    target.type_class.calls.values
  end
end