class GraphQL::Query
  # If a resolve function returns `GraphQL::Query::DEFAULT_RESOLVE`,
  # The executor will send the field's name to the target object
  # and use the result.
  DEFAULT_RESOLVE = :__default_resolve
  attr_reader :schema, :document, :context, :fragments, :variables, :operations, :debug

  # Prepare query `query_string` on `schema`
  # @param schema [GraphQL::Schema]
  # @param query_string [String]
  # @param context [#[]] an arbitrary hash of values which you can access in {GraphQL::Field#resolve}
  # @param variables [Hash] values for `$variables` in the query
  # @param debug [Boolean] if true, errors are raised, if false, errors are put in the `errors` key
  # @param validate [Boolean] if true, `query_string` will be validated with {StaticValidation::Validator}
  # @param operation_name [String] if the query string contains many operations, this is the one which should be executed
  def initialize(schema, query_string, context: nil, variables: {}, debug: true, validate: true, operation_name: nil)
    @schema = schema
    @debug = debug
    @context = Context.new(values: context)

    @variables = variables
    @validate = validate
    @operation_name = operation_name
    @fragments = {}
    @operations = {}

    @document = GraphQL.parse(query_string)
    @document.parts.each do |part|
      if part.is_a?(GraphQL::Language::Nodes::FragmentDefinition)
        @fragments[part.name] = part
      elsif part.is_a?(GraphQL::Language::Nodes::OperationDefinition)
        @operations[part.name] = part
      end
    end
  end

  # Get the result for this query, executing it once
  def result
    if @validate && validation_errors.any?
      return { "errors" => validation_errors }
    end

    @result ||= Executor.new(self, @operation_name).result
  end

  private

  def validation_errors
    @validation_errors ||= @schema.static_validator.validate(@document)
  end

  # Expose some query-specific info to field resolve functions.
  # It delegates `[]` to the hash that's passed to `GraphQL::Query#initialize`.
  class Context
    attr_accessor :execution_strategy
    def initialize(values:)
      @values = values
    end

    def [](key)
      @values[key]
    end

    def async(&block)
      execution_strategy.async(block)
    end
  end
end

require 'graphql/query/arguments'
require 'graphql/query/base_execution'
require 'graphql/query/serial_execution'
require 'graphql/query/parallel_execution'
require 'graphql/query/type_resolver'
require 'graphql/query/directive_chain'
require 'graphql/query/executor'
