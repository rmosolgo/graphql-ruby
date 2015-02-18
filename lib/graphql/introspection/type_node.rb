class GraphQL::Introspection::TypeNode < GraphQL::Node
  cursor :name

  field :name,
    description: "The name of the node",
    type: :string

  field :description,
    description: "Description of the node",
    type: :string

  field :fields,
    type: :connection,
    connection_class_name: "GraphQL::Introspection::Connection",
    node_class_name: "GraphQL::Introspection::FieldNode"

  def fields
    target.all_fields.values
  end

  def name
    schema_name
  end
end