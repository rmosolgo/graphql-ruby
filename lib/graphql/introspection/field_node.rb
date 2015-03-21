class GraphQL::Introspection::FieldNode < GraphQL::Node
  exposes "GraphQL::FieldMapping"
  field.string(:name)
  field.string(:type)
  field.introspection_connection(:calls)

  def calls
    target.field_class.calls.values
  end

  def type
    target.field_class.value_type
  end
end