class GraphQL::Introspection::SchemaNode < GraphQL::Node
  exposes "GraphQL::Schema::Schema"
  field.connection(:calls)
  field.connection(:types)

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