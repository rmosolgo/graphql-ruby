class GraphQL::Introspection::SchemaNode < GraphQL::Node
  field :calls,
    type: :connection,
    connection_class_name: "GraphQL::Introspection::SchemaConnection",
    node_class_name: "GraphQL::Node"

  field :nodes,
    type: :connection,
    connection_class_name: "GraphQL::Introspection::SchemaConnection",
    node_class_name: "GraphQL::Node"
end