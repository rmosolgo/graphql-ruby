class GraphQL::Introspection::FieldNode < GraphQL::Node
  field :name,
    method: :field_name,
    type: :string,
    description: "The name of the field"
  field :type,
    type: :string,
    description: "The type of the field"
  field :description,
    type: :string,
    description: "The description of the field"
  field :calls,
    method: :all_calls,
    type: :connection,
    description: "Calls available on this field",
    connection_class_name: "GraphQL::Introspection::Connection",
    node_class_name: "GraphQL::Introspection::CallNode"
end