class GraphQL::Introspection::RootCallArgumentNode < GraphQL::Node
  exposes "GraphQL::RootCallArgument"
  field.string(:name)
  field.string(:type)
end