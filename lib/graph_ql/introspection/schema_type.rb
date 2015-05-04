class GraphQL::Introspection::SchemaType < GraphQL::Node
  exposes "GraphQL::Schema::Schema"
  desc "The schema for a GraphQL endpoint"
  field.introspection_connection(:calls, "Root calls defined by this schema")
  field.introspection_connection(:types, "Node types defined by this schema")

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