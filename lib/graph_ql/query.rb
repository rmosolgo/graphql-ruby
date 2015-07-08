class GraphQL::Query
  extend ActiveSupport::Autoload
  autoload(:FieldResolutionStrategy)
  autoload(:FragmentSpreadResolutionStrategy)
  autoload(:InlineFragmentResolutionStrategy)
  autoload(:OperationResolver)
  autoload(:SelectionResolver)
  attr_reader :schema, :document, :context, :fragments, :params

  def initialize(schema, query_string, context: nil, params: {})
    @schema = schema
    @document = GraphQL.parse(query_string)
    @context = context
    @params = params
    @fragments = {}
    @operations = {}

    @document.parts.each do |part|
      if part.is_a?(GraphQL::Syntax::FragmentDefinition)
        @fragments[part.name] = part
      elsif part.is_a?(GraphQL::Syntax::OperationDefinition)
        @operations[part.name] = part
      end
    end
  end

  def execute
    response = {}
    @operations.each do |name, operation|
      resolver = OperationResolver.new(operation, self)
      response[name] = resolver.result
    end
    response
  end
end
