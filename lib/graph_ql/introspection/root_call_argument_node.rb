class GraphQL::Introspection::RootCallArgumentNode < GraphQL::Node
  exposes "GraphQL::RootCallArgument"
  desc "An argument to a query root call"
  field.string(:name, "The identifier of this argument")
  field.string(:type, "The type accepted for this argument")
end