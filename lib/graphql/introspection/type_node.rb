class GraphQL::Introspection::TypeNode < GraphQL::Node
  cursor :name

  field :name,
    method: :schema_name,
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
    target.fields.values
  end
end

