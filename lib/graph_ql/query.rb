class GraphQL::Query
  extend ActiveSupport::Autoload
  autoload(:FieldResolver)
  autoload(:OperationResolver)
  autoload(:SelectionResolver)
  attr_reader :schema, :document, :context

  def initialize(schema, query_string, context)
    @schema = schema
    @document = GraphQL.parse(query_string)
    @context = context
    @fragments = {}
    @operations = {}

    @document.parts.each do |part|
      if !part.is_a?(GraphQL::Syntax::OperationDefinition)
        @fragments[part.name] = part
      else
        @operations[part.name] = part
      end
    end
  end

  def execute
    response = {}
    @operations.each do |name, operation|
      resolver = OperationResolver.new(operation, self)
      response[name] = resolver.response
    end
    response
  end
end
