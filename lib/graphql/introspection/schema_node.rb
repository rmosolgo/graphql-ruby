class GraphQL::Introspection::SchemaNode < GraphQL::Node
  field :calls,
    type: :connection,
    connection_class_name: "GraphQL::Introspection::Connection",
    node_class_name: "GraphQL::Introspection::RootCallNode"

  field :nodes,
    type: :connection,
    connection_class_name: "GraphQL::Introspection::Connection",
    node_class_name: "GraphQL::Node"

  def cursor
    "schema"
  end
end