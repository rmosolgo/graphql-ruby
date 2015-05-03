class GraphQL::Introspection::SchemaType < GraphQL::Node
  exposes "GraphQL::Schema::Schema"
  desc "The schema for a GraphQL endpoint"
  field.introspection_connection(:calls)
  field.introspection_connection(:types)

  def cursor
    "schema"
  end

  def types
    @target.types.values
  end

  def calls
    target.calls.values
  end
end