class GraphQL::Introspection::TypeCall < GraphQL::RootCall
  returns __type__: "type"
  def execute!(type_name)
    GraphQL::SCHEMA.get_node(type_name)
  end
end