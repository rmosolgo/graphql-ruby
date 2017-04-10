# frozen_string_literal: true
require "graphql/query/arguments"
require "graphql/query/arguments_cache"
require "graphql/query/context"
require "graphql/query/executor"
require "graphql/query/literal_input"
require "graphql/query/null_context"
require "graphql/query/serial_execution"
require "graphql/query/variables"
require "graphql/query/input_validation_result"
require "graphql/query/variable_validation_error"
require "graphql/query/validation_pipeline"

module GraphQL
  # A combination of query string and {Schema} instance which can be reduced to a {#result}.
  class Query
    extend Forwardable

    class OperationNameMissingError < GraphQL::ExecutionError
      def initialize(name)
        msg = if name.nil?
          %|An operation name is required|
        else
          %|No operation named "#{name}"|
        end
        super(msg)
      end
    end

    attr_reader :schema, :document, :context, :fragments, :operations, :root_value, :query_string, :warden, :provided_variables

    # Prepare query `query_string` on `schema`
    # @param schema [GraphQL::Schema]
    # @param query_string [String]
    # @param context [#[]] an arbitrary hash of values which you can access in {GraphQL::Field#resolve}
    # @param variables [Hash] values for `$variables` in the query
    # @param operation_name [String] if the query string contains many operations, this is the one which should be executed
    # @param root_value [Object] the object used to resolve fields on the root type
    # @param max_depth [Numeric] the maximum number of nested selections allowed for this query (falls back to schema-level value)
    # @param max_complexity [Numeric] the maximum field complexity for this query (falls back to schema-level value)
    # @param except [<#call(schema_member, context)>] If provided, objects will be hidden from the schema when `.call(schema_member, context)` returns truthy
    # @param only [<#call(schema_member, context)>] If provided, objects will be hidden from the schema when `.call(schema_member, context)` returns false
    def initialize(schema, query_string = nil, document: nil, context: nil, variables: {}, validate: true, operation_name: nil, root_value: nil, max_depth: nil, max_complexity: nil, except: nil, only: nil)
      fail ArgumentError, "a query string or document is required" unless query_string || document

      @schema = schema
      mask = GraphQL::Schema::Mask.combine(schema.default_mask, except: except, only: only)
      @context = Context.new(query: self, values: context)
      @warden = GraphQL::Schema::Warden.new(mask, schema: @schema, context: @context)
      @root_value = root_value
      @fragments = {}
      @operations = {}
      if variables.is_a?(String)
        raise ArgumentError, "Query variables should be a Hash, not a String. Try JSON.parse to prepare variables."
      else
        @provided_variables = variables
      end
      @query_string = query_string
      parse_error = nil
      @document = document || begin
        GraphQL.parse(query_string)
      rescue GraphQL::ParseError => err
        parse_error = err
        @schema.parse_error(err, @context)
        nil
      end

      @document && @document.definitions.each do |part|
        case part
        when GraphQL::Language::Nodes::FragmentDefinition
          @fragments[part.name] = part
        when GraphQL::Language::Nodes::OperationDefinition
          @operations[part.name] = part
        end
      end

      @resolved_types_cache = Hash.new { |h, k| h[k] = @schema.resolve_type(k, @context) }

      @arguments_cache = ArgumentsCache.build(self)

      # Trying to execute a document
      # with no operations returns an empty hash
      @ast_variables = []
      @mutation = false
      operation_name_error = nil
      if @operations.any?
        @selected_operation = find_operation(@operations, operation_name)
        if @selected_operation.nil?
          operation_name_error = GraphQL::Query::OperationNameMissingError.new(operation_name)
        else
          @ast_variables = @selected_operation.variables
          @mutation = @selected_operation.operation_type == "mutation"
        end
      end

      @validation_pipeline = GraphQL::Query::ValidationPipeline.new(
        query: self,
        parse_error: parse_error,
        operation_name_error: operation_name_error,
        max_depth: max_depth || schema.max_depth,
        max_complexity: max_complexity || schema.max_complexity,
      )

      @result = nil
      @executed = false
    end

    # Get the result for this query, executing it once
    # @return [Hash] A GraphQL response, with `"data"` and/or `"errors"` keys
    def result
      if @executed
        @result
      else
        @executed = true
        instrumenters = @schema.instrumenters[:query]
        begin
          instrumenters.each { |i| i.before_query(self) }
          @result = if !valid?
            all_errors = validation_errors + analysis_errors + context.errors
            if all_errors.any?
              { "errors" => all_errors.map(&:to_h) }
            else
              nil
            end
          else
            Executor.new(self).result
          end
        ensure
          instrumenters.each { |i| i.after_query(self) }
        end
      end
    end


    # This is the operation to run for this query.
    # If more than one operation is present, it must be named at runtime.
    # @return [GraphQL::Language::Nodes::OperationDefinition, nil]
    attr_reader :selected_operation

    # Determine the values for variables of this query, using default values
    # if a value isn't provided at runtime.
    #
    # If some variable is invalid, errors are added to {#validation_errors}.
    #
    # @return [GraphQL::Query::Variables] Variables to apply to this query
    def variables
      @variables ||= begin
        vars = GraphQL::Query::Variables.new(
          @context,
          @ast_variables,
          @provided_variables,
        )
        vars
      end
    end

    def irep_selection
      @selection ||= internal_representation[selected_operation.name]
    end

    # Node-level cache for calculating arguments. Used during execution and query analysis.
    # @api private
    # @return [GraphQL::Query::Arguments] Arguments for this node, merging default values, literal values and query variables
    def arguments_for(irep_or_ast_node, definition)
      @arguments_cache[irep_or_ast_node][definition]
    end

    # @return [GraphQL::Language::Nodes::Document, nil]
    attr_reader :selected_operation

    def_delegators :@validation_pipeline, :valid?, :analysis_errors, :validation_errors, :internal_representation

    def_delegators :@warden, :get_type, :get_field, :possible_types, :root_type_for_operation

    # @param value [Object] Any runtime value
    # @return [GraphQL::ObjectType, nil] The runtime type of `value` from {Schema#resolve_type}
    # @see {#possible_types} to apply filtering from `only` / `except`
    def resolve_type(value)
      @resolved_types_cache[value]
    end

    def mutation?
      @mutation
    end

    private

    def find_operation(operations, operation_name)
      if operation_name.nil? && operations.length == 1
        operations.values.first
      elsif !operations.key?(operation_name)
        nil
      else
        operations.fetch(operation_name)
      end
    end
  end
end
