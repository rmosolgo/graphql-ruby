class GraphQL::Introspection::RootCallNode < GraphQL::Node
  field :name, method: :schema_name
  field :returns
end