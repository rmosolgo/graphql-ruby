# A GraphQL schema which may be queried with {GraphQL::Query}.
class GraphQL::Schema
  DIRECTIVES = [GraphQL::Directive::SkipDirective, GraphQL::Directive::IncludeDirective]
  DYNAMIC_FIELDS = ["__type", "__typename", "__schema"]

  attr_reader :query, :mutation, :directives, :static_validator

  # @param query [GraphQL::ObjectType]  the query root for the schema
  # @param mutation [GraphQL::ObjectType, nil] the mutation root for the schema
  def initialize(query:, mutation: nil)
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
    @types ||= TypeReducer.find_all([query, mutation, GraphQL::Introspection::SchemaType].compact)
  end

  # Resolve field named `field_name` for type `parent_type`.
  # Handles dynamic fields `__typename`, `__type` and `__schema`, too
  def get_field(parent_type, field_name)
    defined_field = parent_type.fields[field_name]
    if defined_field
      defined_field
    elsif field_name == "__typename"
      GraphQL::Introspection::TypenameField.create(parent_type)
    elsif field_name == "__schema" && parent_type == query
      GraphQL::Introspection::SchemaField.create(self)
    elsif field_name == "__type" && parent_type == query
      GraphQL::Introspection::TypeByNameField.create(self.types)
    else
      nil
    end
  end
end

require 'graph_ql/schema/each_item_validator'
require 'graph_ql/schema/field_validator'
require 'graph_ql/schema/implementation_validator'
require 'graph_ql/schema/schema_validator'
require 'graph_ql/schema/type_reducer'
require 'graph_ql/schema/type_validator'
