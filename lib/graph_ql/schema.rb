class GraphQL::Schema
  extend ActiveSupport::Autoload
  autoload(:TypeReducer)

  attr_reader :query, :mutation
  def initialize(query:, mutation:)
    # Add fields to this query root for introspection:
    query.fields = query.fields.merge({
      "__type" => GraphQL::TypeField.new(self),
    })
    # query.fields["__schema"] = GraphQL::SchemaField.new(self)

    @query    = query
    @mutation = mutation
  end

  def types
    @types ||= TypeReducer.new(query, {}).result
  end
end
