class GraphQL::Introspection::TypeType < GraphQL::Node
  exposes "GraphQL::Node"
  type "__type__"
  field.string(:name)
  field.string(:description)
  field.introspection_connection(:fields)

  cursor :name

  # they're actually {FieldMapping}s
  def fields
    target.all_fields.values
  end

  def name
    schema_name
  end
end