class GraphQL::Schema
  extend ActiveSupport::Autoload
  autoload(:FieldValidator)
  autoload(:ImplementationValidator)
  autoload(:SchemaValidator)
  autoload(:TypeReducer)
  autoload(:TypeValidator)
  autoload(:UnionValidator)
  DIRECTIVES = [GraphQL::SkipDirective, GraphQL::IncludeDirective]

  attr_reader :query, :mutation, :directives
  def initialize(query:, mutation:)
    # Add fields to this query root for introspection:
    query.fields = query.fields.merge({
      "__type" =>     GraphQL::Field.new do |f|
        f.description("A type in the GraphQL system")
        f.type(!GraphQL::Introspection::TypeType)
        f.resolve -> (o, a, c) { self.types[a["name"]] }
      end,
      "__schema" =>   GraphQL::Field.new do |f|
        f.description("This GraphQL schema")
        f.type(!GraphQL::Introspection::SchemaType)
        f.resolve -> (o, a, c) { self }
      end
    })

    @query    = query
    @mutation = mutation
    @directives = DIRECTIVES.reduce({}) { |m, d| m[d.name] = d; m }
    @static_validator = GraphQL::StaticValidation::Validator.new(schema: self)

    errors = SchemaValidator.new.validate(self)
    if errors.any?
      raise("Schema is invalid: \n#{errors.join("\n")}")
    end
  end

  def types
    @types ||= TypeReducer.new(query, {}).result
  end
end
