class GraphQL::Introspection::RootCallType < GraphQL::Node
  exposes "GraphQL::RootCall"
  desc "A call that can be used as the root of a query"

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

  def arguments
    target.arguments.values
  end
end