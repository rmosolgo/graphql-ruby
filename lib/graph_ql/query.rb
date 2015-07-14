class GraphQL::Query
  DEFAULT_RESOLVE = :__default_resolve
  extend ActiveSupport::Autoload
  autoload(:Arguments)
  autoload(:FieldResolutionStrategy)
  autoload(:FragmentSpreadResolutionStrategy)
  autoload(:InlineFragmentResolutionStrategy)
  autoload(:OperationResolver)
  autoload(:SelectionResolver)
  autoload(:TypeResolver)
  attr_reader :schema, :document, :context, :fragments, :params

  def initialize(schema, query_string, context: nil, params: {}, debug: true, validate: true)
    @schema = schema
    @debug = debug
    @query_string = query_string
    @context = context
    @params = params
    @validate = validate
    @fragments = {}
    @operations = {}

    @document = GraphQL.parse(@query_string)
    @document.parts.each do |part|
      if part.is_a?(GraphQL::Nodes::FragmentDefinition)
        @fragments[part.name] = part
      elsif part.is_a?(GraphQL::Nodes::OperationDefinition)
        @operations[part.name] = part
      end
    end
  end

  # Get the result for this query, executing it once
  def result
    if validation_errors.any?
      return { "errors" => validation_errors }
    end

    @result ||= {
      "data" => execute,
    }
  rescue StandardError => err
    if @debug
      raise err
    else
      message = "Something went wrong during query execution: #{err}"
      {"errors" => [{"message" => message}]}
    end
  end

  private

  def execute
    response = {}
    @operations.each do |name, operation|
      resolver = OperationResolver.new(operation, self)
      response[name] = resolver.result
    end
    response
  end

  def validation_errors
    @validation_errors ||= begin
      if @validate
        @schema.static_validator.validate(@document)
      else
        []
      end
    end
  end
end
