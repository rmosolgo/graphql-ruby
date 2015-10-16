class GraphQL::Query
  class OperationNameMissingError < StandardError
    def initialize(names)
      msg = "You must provide an operation name from: #{names.join(", ")}"
      super(msg)
    end
  end

  # If a resolve function returns `GraphQL::Query::DEFAULT_RESOLVE`,
  # The executor will send the field's name to the target object
  # and use the result.
  DEFAULT_RESOLVE = :__default_resolve
  attr_reader :schema, :document, :context, :fragments, :operations, :debug

  # Prepare query `query_string` on `schema`
  # @param schema [GraphQL::Schema]
  # @param query_string [String]
  # @param context [#[]] an arbitrary hash of values which you can access in {GraphQL::Field#resolve}
  # @param variables [Hash] values for `$variables` in the query
  # @param debug [Boolean] if true, errors are raised, if false, errors are put in the `errors` key
  # @param validate [Boolean] if true, `query_string` will be validated with {StaticValidation::Validator}
  # @param operation_name [String] if the query string contains many operations, this is the one which should be executed
  def initialize(schema, query_string, context: nil, variables: {}, debug: false, validate: true, operation_name: nil)
    @schema = schema
    @debug = debug
    @context = Context.new(values: context)
    @validate = validate
    @operation_name = operation_name
    @fragments = {}
    @operations = {}
    @provided_variables = variables
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


  def selected_operation
    @selected_operation ||= begin
      if operations.length == 1
        operations.values.first
      elsif operations.length == 0
        nil
      elsif !operations.key?(@operation_name)
        raise OperationNameMissingError, operations.keys
      else
        operations[@operation_name]
      end
    end
  end

  def variables
    @variables ||= begin
      selected_operation.variables.each_with_object({}) { |ast_variable, memo|
        variable_type = schema.type_from_ast(ast_variable.type)
        variable_name = ast_variable.name
        default_value = ast_variable.default_value
        provided_value = @provided_variables[variable_name]
        if !provided_value.nil?
          # coerce the Ruby value to a GraphQL query value
          graphql_value = GraphQL::Query::RubyInput.coerce(variable_type, provided_value)
        elsif !default_value.nil?
          # coerce the AST value to a GraphQL query value
          # reduced_value = reduce_value(ast_variable.default_value, variable_type)
          graphql_value = GraphQL::Query::LiteralInput.coerce(variable_type, default_value, {})
        end
        memo[variable_name] = graphql_value
      }
    end
  end

  private

  def validation_errors
    @validation_errors ||= schema.static_validator.validate(document)
  end
end

require 'graphql/query/arguments'
require 'graphql/query/base_execution'
require 'graphql/query/literal_input'
require 'graphql/query/ruby_input'
require 'graphql/query/serial_execution'
require 'graphql/query/type_resolver'
require 'graphql/query/directive_chain'
require 'graphql/query/executor'
require 'graphql/query/context'
