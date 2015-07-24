# Initialized with a {GraphQL::Schema}, then it can validate {GraphQL::Nodes::Documents}s based on that schema.
#
# By default, it's used by {GraphQL::Query}
class GraphQL::StaticValidation::Validator
  def initialize(schema:, rules: GraphQL::StaticValidation::ALL_RULES)
    @schema = schema
    @rules = rules
  end

  def validate(document)
    context = Context.new(@schema, document)
    @rules.each do |rules|
      rules.new.validate(context)
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
