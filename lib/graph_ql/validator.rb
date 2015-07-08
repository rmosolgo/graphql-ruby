class GraphQL::Validator
  VALIDATORS = [
    GraphQL::Validations::FragmentsAreUsed,
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
    context.errors
  end

  class Context
    attr_reader :schema, :document, :errors, :visitor
    def initialize(schema, document)
      @schema = schema
      @document = document
      @visitor = GraphQL::Visitor.new
      @errors = []
    end
  end
end
