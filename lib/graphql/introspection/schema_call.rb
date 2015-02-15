class GraphQL::Introspection::SchemaCall < GraphQL::RootCall
  returns :schema
  arguments(nil)

  def execute!
    GraphQL::SCHEMA
  end
end