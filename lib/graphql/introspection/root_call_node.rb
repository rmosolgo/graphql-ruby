class GraphQL::Introspection::RootCallNode < GraphQL::Node
  exposes "GraphQL::RootCall"
  field.string(:name)
  field.string(:returns)
  field.introspection_connection(:arguments)


  def returns
    return_declarations = @target.return_declarations
    return_declarations.keys.map(&:to_s)
  end

  def name
    schema_name
  end
end