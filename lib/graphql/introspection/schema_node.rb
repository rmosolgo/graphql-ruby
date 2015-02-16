class GraphQL::Introspection::SchemaNode < GraphQL::Node
  field :calls,
    type: :connection,
    connection_class_name: "GraphQL::Introspection::Connection",
    node_class_name: "GraphQL::Introspection::RootCallNode"

  field :types,
    method: :nodes,
    type: :connection,
    connection_class_name: "GraphQL::Introspection::Connection",
    node_class_name: "GraphQL::Introspection::TypeNode"

  def cursor
    "schema"
  end
end