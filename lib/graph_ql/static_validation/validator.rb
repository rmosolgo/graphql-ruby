# Initialized with a {GraphQL::Schema}, then it can validate {GraphQL::Nodes::Documents}s based on that schema.
#
# By default, it's used by {GraphQL::Query}
class GraphQL::StaticValidation::Validator
  # Order is important here. Some validators return {GraphQL::Visitor::SKIP}
  # which stops the visit on that node. That way it doesn't try to find fields on types that
  # don't exist, etc.
  VALIDATORS = [
    GraphQL::StaticValidation::DirectivesAreDefined,
    GraphQL::StaticValidation::ArgumentsAreDefined,
    GraphQL::StaticValidation::RequiredArgumentsArePresent,
    GraphQL::StaticValidation::ArgumentLiteralsAreCompatible,
    GraphQL::StaticValidation::FragmentTypesExist,
    GraphQL::StaticValidation::FragmentsAreOnCompositeTypes,
    GraphQL::StaticValidation::FragmentsAreFinite,
    GraphQL::StaticValidation::FragmentSpreadsArePossible,
    GraphQL::StaticValidation::FragmentsAreUsed,
    GraphQL::StaticValidation::FieldsAreDefinedOnType,
    GraphQL::StaticValidation::FieldsWillMerge,
    GraphQL::StaticValidation::FieldsHaveAppropriateSelections,
    GraphQL::StaticValidation::VariablesAreInputTypes,
    GraphQL::StaticValidation::VariableDefaultValuesAreCorrectlyTyped,
    GraphQL::StaticValidation::VariablesAreUsedAndDefined,
    GraphQL::StaticValidation::VariableUsagesAreAllowed,
  ]

  def initialize(schema:, validators: VALIDATORS)
    @schema = schema
    @validators = validators
  end

  def validate(document)
    context = Context.new(@schema, document)
    @validators.each do |validator|
      validator.new.validate(context)
    end
    context.visitor.visit(document)
    context.errors.map(&:to_h)
  end

  class Context
    attr_reader :schema, :document, :errors, :visitor, :fragments
    def initialize(schema, document)
      @schema = schema
      @document = document
      @fragments = {}
      @errors = []
      @visitor = GraphQL::Visitor.new
      @visitor[GraphQL::Nodes::FragmentDefinition] << -> (node, parent) { @fragments[node.name] = node }
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
  end
end
