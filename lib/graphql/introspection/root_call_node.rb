class GraphQL::Introspection::RootCallNode < GraphQL::Node
  field :name
  field :returns

  field :arguments,
    type: :connection,
    connection_class_name: "GraphQL::Introspection::Connection",
    node_class_name: "GraphQL::Introspection::RootCallArgumentNode"

  def returns
    return_declarations = @target.return_declarations
    return_declarations.keys.map(&:to_s)
  end

  def arguments
    @target.argument_declarations
  end

  def name
    schema_name
  end
end