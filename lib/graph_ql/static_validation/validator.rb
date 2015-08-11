# Initialized with a {GraphQL::Schema}, then it can validate {GraphQL::Nodes::Documents}s based on that schema.
#
# By default, it's used by {GraphQL::Query}
#
# @example Validate a query
#   validator = GraphQL::StaticValidation::Validator.new(schema: MySchema)
#   document = GraphQL.parse(query_string)
#   errors = validator.validate(document)
#
class GraphQL::StaticValidation::Validator
  # @param schema [GraphQL::Schema]
  # @param rule [Array<#validate(context)>] a list of rules to use when validating
  def initialize(schema:, rules: GraphQL::StaticValidation::ALL_RULES)
    @schema = schema
    @rules = rules
  end

  # Validate `document` against the schema. Returns an array of message hashes.
  # @param document [GraphQL::Nodes::Document]
  # @return [Array<Hash>]
  def validate(document)
    context = Context.new(@schema, document)
    @rules.each do |rules|
      rules.new.validate(context)
    end
    context.visitor.visit(document)
    context.errors.map(&:to_h)
  end

  # The validation context gets passed to each validator.
  #
  # It exposes a {GraphQL::Visitor} where validators may add hooks. ({Visitor#visit} is called in {Validator#validate})
  #
  # It provides access to the schema & fragments which validators may read from.
  #
  # It holds a list of errors which each validator may add to.
  #
  # It also provides limited access to the {TypeStack} instance,
  # which tracks state as you climb in and out of different fields.
  class Context
    attr_reader :schema, :document, :errors, :visitor, :fragments
    def initialize(schema, document)
      @schema = schema
      @document = document
      @fragments = document.parts.each_with_object({}) do |part, memo|
        part.is_a?(GraphQL::Nodes::FragmentDefinition) && memo[part.name] = part
      end
      @errors = []
      @visitor = GraphQL::Visitor.new
      @type_stack = GraphQL::StaticValidation::TypeStack.new(schema, visitor)
    end

    def object_types
      @type_stack.object_types
    end

    def field_definition
      @type_stack.field_definitions.last
    end

    def directive_definition
      @type_stack.directive_definitions.last
    end

    # Don't try to validate dynamic fields
    # since they aren't defined by the type system
    def skip_field?(field_name)
      GraphQL::Schema::DYNAMIC_FIELDS.include?(field_name)
    end
  end
end
