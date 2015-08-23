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
  end

  # A `{ name => type }` hash of types in this schema
  # @returns Hash
  def types
    @types ||= TypeReducer.find_all([query, mutation, GraphQL::Introspection::SchemaType].compact)
  end

  # Resolve field named `field_name` for type `parent_type`.
  # Handles dynamic fields `__typename`, `__type` and `__schema`, too
  def get_field(parent_type, field_name, strict: false)
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
      strict && raise("No such field #{field_name} on #{parent_type}")
      nil
    end
  rescue StandardError => e
    raise RuntimeError, "Failed to get field #{field_name} on type #{parent_type}"
  end

  class InvalidTypeError < StandardError
    def initialize(type, errors)
      super("Type #{type.respond_to?(:name) ? type.name :  "Unnamed type" } is invalid: #{errors.join(", ")}")
    end
  end
end

require 'graphql/schema/each_item_validator'
require 'graphql/schema/field_validator'
require 'graphql/schema/implementation_validator'
require 'graphql/schema/type_reducer'
require 'graphql/schema/type_validator'
