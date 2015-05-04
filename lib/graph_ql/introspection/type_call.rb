class GraphQL::Introspection::TypeCall < GraphQL::RootCall
  returns :type
  argument.string("type_name")

  def execute(type_name)
    GraphQL::SCHEMA.get_type(type_name)
  end
end