class GraphQL::StaticValidation::Validator
  VALIDATORS = [
    GraphQL::StaticValidation::DirectivesAreDefined,
    GraphQL::StaticValidation::ArgumentsAreDefined,
    GraphQL::StaticValidation::RequiredArgumentsArePresent,
    GraphQL::StaticValidation::ArgumentLiteralsAreCompatible,
    GraphQL::StaticValidation::FragmentTypesExist,
    GraphQL::StaticValidation::FragmentsAreUsed,
    GraphQL::StaticValidation::FieldsAreDefinedOnType,
    GraphQL::StaticValidation::FieldsWillMerge,
    GraphQL::StaticValidation::FieldsHaveAppropriateSelections,
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
  end
end
