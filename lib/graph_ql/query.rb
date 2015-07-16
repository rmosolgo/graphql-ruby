class GraphQL::Query
  # If a resolve function returns `GraphQL::Query::DEFAULT_RESOLVE`,
  # The executor will send the field's name to the target object
  # and use the result.
  DEFAULT_RESOLVE = :__default_resolve
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
      message = "Something went wrong during query execution: #{err}" # \n  #{err.backtrace.join("\n  ")}"
      {"errors" => [{"message" => message}]}
    end
  end

  private

  def execute
    @operations.reduce({}) do |memo, (name, operation)|
      resolver = OperationResolver.new(operation, self)
      memo[name] = resolver.result
      memo
    end
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

require 'graph_ql/query/arguments'
require 'graph_ql/query/field_resolution_strategy'
require 'graph_ql/query/fragment_spread_resolution_strategy'
require 'graph_ql/query/inline_fragment_resolution_strategy'
require 'graph_ql/query/operation_resolver'
require 'graph_ql/query/selection_resolver'
require 'graph_ql/query/type_resolver'
