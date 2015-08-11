# A GraphQL schema which may be queried with {GraphQL::Query}.
class GraphQL::Schema
  DIRECTIVES = [GraphQL::Directive::SkipDirective, GraphQL::Directive::IncludeDirective]

  attr_reader :query, :mutation, :directives, :static_validator

  # @param query [GraphQL::ObjectType]  the query root for the schema
  # @param mutation [GraphQL::ObjectType, nil] the mutation root for the schema
  def initialize(query:, mutation:)
    # Add fields to this query root for introspection:
    query.fields = query.fields.merge({
      "__type" =>     GraphQL::Field.new do |f, type, field, arg|
        f.description("A type in the GraphQL system")
        f.arguments({name: arg.build(type: !type.String)})
        f.type(!GraphQL::Introspection::TypeType)
        f.resolve -> (o, a, c) { self.types[a["name"]] }
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

  # A `{ name => type }` hash of types in this schema
  # @returns Hash
  def types
    @types ||= TypeReducer.new(query, {}).result
  end

  # Resolve field named `field_name` for type `parent_type`.
  # Handles dynamic fields `__typename` and `__schema`, too
  def get_field(parent_type, field_name)
    if field_name == "__typename"
      GraphQL::Introspection::TypenameField.create(parent_type)
    elsif field_name == "__schema" && parent_type == query
      GraphQL::Introspection::SchemaField.create(self)
    else
      parent_type.fields[field_name]
    end
  end
end

require 'graph_ql/schema/each_item_validator'
require 'graph_ql/schema/field_validator'
require 'graph_ql/schema/implementation_validator'
require 'graph_ql/schema/schema_validator'
require 'graph_ql/schema/type_reducer'
require 'graph_ql/schema/type_validator'
