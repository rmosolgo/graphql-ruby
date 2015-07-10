class GraphQL::Query
  DEFAULT_RESOLVE = :__default_resolve
  extend ActiveSupport::Autoload
  autoload(:FieldResolutionStrategy)
  autoload(:FragmentSpreadResolutionStrategy)
  autoload(:InlineFragmentResolutionStrategy)
  autoload(:OperationResolver)
  autoload(:SelectionResolver)
  autoload(:TypeResolver)
  attr_reader :schema, :document, :context, :fragments, :params

  def initialize(schema, query_string, context: nil, params: {})
    @schema = schema
    @document = GraphQL.parse(query_string)
    @context = context
    @params = params
    @fragments = {}
    @operations = {}

    @document.parts.each do |part|
      if part.is_a?(GraphQL::Nodes::FragmentDefinition)
        @fragments[part.name] = part
      elsif part.is_a?(GraphQL::Nodes::OperationDefinition)
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
