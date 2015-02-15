class GraphQL::Introspection::SchemaCall < GraphQL::RootCall
  def execute!
    {
      "schema" => GraphQL::SCHEMA,
      "__type__" => GraphQL::Introspection::SchemaNode,
    }
  end
end