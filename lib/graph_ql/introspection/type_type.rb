class GraphQL::Introspection::TypeType < GraphQL::Node
  exposes "GraphQL::Node"
  desc "A node type in this GraphQL system"
  type "__type__"
  field.string(:name, "The identifier for this node type")
  field.string(:description, "The description of this node type")
  field.introspection_connection(:fields, "Fields exposed by this node type")

  cursor :name

  # they're actually {FieldMapping}s
  def fields
    target.all_fields.values
  end

  def name
    schema_name
  end
end