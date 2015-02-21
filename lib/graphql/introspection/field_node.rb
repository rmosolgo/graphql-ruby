class GraphQL::Introspection::FieldNode < GraphQL::Node
  exposes "GraphQL::Field"
  field.string(:name)
  field.string(:type)
  field.string(:description)
  field.connection(:calls)

  def calls
    target.calls.values
  end

  def name
    schema_name
  end

  def type
    value_type
  end
end