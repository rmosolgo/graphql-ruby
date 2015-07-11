class GraphQL::Schema
  extend ActiveSupport::Autoload
  autoload(:TypeReducer)
  DIRECTIVES = [GraphQL::SkipDirective, GraphQL::IncludeDirective]

  attr_reader :query, :mutation, :directives
  def initialize(query:, mutation:)
    # Add fields to this query root for introspection:
    query.fields = query.fields.merge({
      "__type" =>     GraphQL::Field.new do |f|
        f.description("A type in the GraphQL system")
        f.type(!GraphQL::TypeType)
        f.resolve -> (o, a, c) { self.types[a["name"]] || raise("No type found in schema for '#{a["name"]}'") }
      end,
      "__schema" =>   GraphQL::Field.new do |f|
        f.description("This GraphQL schema")
        f.type(!GraphQL::SchemaType)
        f.resolve -> (o, a, c) { self }
      end
    })

    @query    = query
    @mutation = mutation
    @directives = DIRECTIVES.reduce({}) { |m, d| m[d.name] = d; m }
  end

  def types
    @types ||= TypeReducer.new(query, {}).result
  end
end
