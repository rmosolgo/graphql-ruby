class GraphQL::Introspection::SchemaCall < GraphQL::RootCall
  returns __type__: "schema"

  def execute!
    GraphQL::SCHEMA
  end
end