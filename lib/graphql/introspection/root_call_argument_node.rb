class GraphQL::Introspection::RootCallArgumentNode < GraphQL::Node
  exposes "GraphQL::RootCallArgument"
  desc "An argument to a query root call"
  field.string(:name)
  field.string(:type)
end