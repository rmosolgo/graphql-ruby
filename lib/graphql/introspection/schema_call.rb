class GraphQL::Introspection::SchemaCall < GraphQL::RootCall
  returns :schema
  argument.none

  def execute!
    GraphQL::SCHEMA
  end
end