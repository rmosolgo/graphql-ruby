class GraphQL::Introspection::TypeCall < GraphQL::RootCall
  def execute!(type_name)
    {
      type_name => GraphQL::SCHEMA.get_node(type_name),
      "__type__" => GraphQL::Introspection::TypeNode
    }
  end
end