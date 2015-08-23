class GraphQL::Query
  # If a resolve function returns `GraphQL::Query::DEFAULT_RESOLVE`,
  # The executor will send the field's name to the target object
  # and use the result.
  DEFAULT_RESOLVE = :__default_resolve
  attr_reader :schema, :document, :context, :fragments, :variables

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
    @context = Context.new(context)

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

    @result ||= { "data" => execute }

  rescue OperationNameMissingError => err
    {"errors" => [{"message" => err.message}]}
  rescue StandardError => err
    @debug && raise(err)
    message = "Something went wrong during query execution: #{err}" # \n  #{err.backtrace.join("\n  ")}"
    {"errors" => [{"message" => message}]}
  end

  private

  def execute
    return {} if @operations.none?
    operation = find_operation(@operation_name, @operations)
    resolver = OperationResolver.new(operation, self)
    resolver.result
  end

  def validation_errors
    @validation_errors ||= @schema.static_validator.validate(@document)
  end

  def find_operation(operation_name, operations)
    if operations.length == 1
      operations.values.first
    elsif !operations.key?(operation_name)
      raise OperationNameMissingError, operations.keys
    else
      operations[operation_name]
    end
  end

  # Expose some query-specific info to field resolve functions.
  # It delegates `[]` to the hash that's passed to `GraphQL::Query#initialize`.
  class Context
    def initialize(arbitrary_hash)
      @arbitrary_hash = arbitrary_hash
    end

    def [](key)
      @arbitrary_hash[key]
    end
  end

  class OperationNameMissingError < StandardError
    def initialize(names)
      msg = "You must provide an operation name from: #{names.join(", ")}"
      super(msg)
    end
  end
end

require 'graphql/query/arguments'
require 'graphql/query/field_resolution_strategy'
require 'graphql/query/fragment_spread_resolution_strategy'
require 'graphql/query/inline_fragment_resolution_strategy'
require 'graphql/query/operation_resolver'
require 'graphql/query/selection_resolver'
require 'graphql/query/type_resolver'
require 'graphql/query/directive_chain'
