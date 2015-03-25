class GraphQL::Introspection::FieldType < GraphQL::Node
  exposes "GraphQL::Field"
  field.string(:name)
  field.string(:type)
  field.introspection_connection(:calls)

  def calls
    target.type_class.calls.values
  end
end