class GraphQL::Schema
  DIRECTIVES = [GraphQL::SkipDirective, GraphQL::IncludeDirective]

  attr_reader :query, :mutation, :directives, :static_validator
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

require 'graph_ql/schema/field_validator'
require 'graph_ql/schema/implementation_validator'
require 'graph_ql/schema/schema_validator'
require 'graph_ql/schema/type_reducer'
require 'graph_ql/schema/type_validator'
require 'graph_ql/schema/union_validator'
