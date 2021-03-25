# frozen_string_literal: true
require "graphql/query/arguments"
require "graphql/query/arguments_cache"
require "graphql/query/context"
require "graphql/query/executor"
require "graphql/query/fingerprint"
require "graphql/query/literal_input"
require "graphql/query/null_context"
require "graphql/query/result"
require "graphql/query/serial_execution"
require "graphql/query/variables"
require "graphql/query/input_validation_result"
require "graphql/query/variable_validation_error"
require "graphql/query/validation_pipeline"

module GraphQL
  # A combination of query string and {Schema} instance which can be reduced to a {#result}.
  class Query
    include Tracing::Traceable
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

    attr_reader :schema, :context, :provided_variables

    # The value for root types
    attr_accessor :root_value

    # @return [nil, String] The operation name provided by client or the one inferred from the document. Used to determine which operation to run.
    attr_accessor :operation_name

    # @return [Boolean] if false, static validation is skipped (execution behavior for invalid queries is undefined)
    attr_accessor :validate

    attr_writer :query_string

    # @return [GraphQL::Language::Nodes::Document]
    def document
      # It's ok if this hasn't been assigned yet
      if @query_string || @document
        with_prepared_ast { @document }
      else
        nil
      end
    end

    def inspect
      "query ..."
    end

    # @return [String, nil] The name of the operation to run (may be inferred)
    def selected_operation_name
      return nil unless selected_operation
      selected_operation.name
    end

    # @return [String, nil] the triggered event, if this query is a subscription update
    attr_reader :subscription_topic

    attr_reader :tracers

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
    def initialize(schema, query_string = nil, query: nil, document: nil, context: nil, variables: nil, validate: true, subscription_topic: nil, operation_name: nil, root_value: nil, max_depth: schema.max_depth, max_complexity: schema.max_complexity, except: nil, only: nil, warden: nil)
      # Even if `variables: nil` is passed, use an empty hash for simpler logic
      variables ||= {}

      # Use the `.graphql_definition` here which will return legacy types instead of classes
      if schema.is_a?(Class) && !schema.interpreter?
        schema = schema.graphql_definition
      end
      @schema = schema
      @interpreter = @schema.interpreter?
      @filter = schema.default_filter.merge(except: except, only: only)
      @context = schema.context_class.new(query: self, object: root_value, values: context)
      @warden = warden
      @subscription_topic = subscription_topic
      @root_value = root_value
      @fragments = nil
      @operations = nil
      @validate = validate
      @tracers = schema.tracers + (context ? context.fetch(:tracers, []) : [])
      # Support `ctx[:backtrace] = true` for wrapping backtraces
      if context && context[:backtrace] && !@tracers.include?(GraphQL::Backtrace::Tracer)
        @tracers << GraphQL::Backtrace::Tracer
      end

      @analysis_errors = []
      if variables.is_a?(String)
        raise ArgumentError, "Query variables should be a Hash, not a String. Try JSON.parse to prepare variables."
      else
        @provided_variables = variables || {}
      end

      @query_string = query_string || query
      @document = document

      if @query_string && @document
        raise ArgumentError, "Query should only be provided a query string or a document, not both."
      end

      # A two-layer cache of type resolution:
      # { abstract_type => { value => resolved_type } }
      @resolved_types_cache = Hash.new do |h1, k1|
        h1[k1] = Hash.new do |h2, k2|
          h2[k2] = @schema.resolve_type(k1, k2, @context)
        end
      end

      # Trying to execute a document
      # with no operations returns an empty hash
      @ast_variables = []
      @mutation = false
      @operation_name = operation_name
      @prepared_ast = false
      @validation_pipeline = nil
      @max_depth = max_depth
      @max_complexity = max_complexity

      @result_values = nil
      @executed = false

      # TODO add a general way to define schema-level filters
      if @schema.respond_to?(:visible?)
        merge_filters(only: @schema.method(:visible?))
      end
    end

    # If a document was provided to `GraphQL::Schema#execute` instead of the raw query string, we will need to get it from the document
    def query_string
      @query_string ||= (document ? document.to_query_string : nil)
    end

    def interpreter?
      @interpreter
    end

    attr_accessor :multiplex

    def subscription_update?
      @subscription_topic && subscription?
    end

    # A lookahead for the root selections of this query
    # @return [GraphQL::Execution::Lookahead]
    def lookahead
      @lookahead ||= begin
        ast_node = selected_operation
        root_type = warden.root_type_for_operation(ast_node.operation_type || "query")
        root_type = root_type.type_class || raise("Invariant: `lookahead` only works with class-based types")
        GraphQL::Execution::Lookahead.new(query: self, root_type: root_type, ast_nodes: [ast_node])
      end
    end

    # @api private
    def result_values=(result_hash)
      if @executed
        raise "Invariant: Can't reassign result"
      else
        @executed = true
        @result_values = result_hash
      end
    end

    # @api private
    attr_reader :result_values

    def fragments
      with_prepared_ast { @fragments }
    end

    def operations
      with_prepared_ast { @operations }
    end

    # Get the result for this query, executing it once
    # @return [Hash] A GraphQL response, with `"data"` and/or `"errors"` keys
    def result
      if !@executed
        Execution::Multiplex.run_queries(@schema, [self], context: @context)
      end
      @result ||= Query::Result.new(query: self, values: @result_values)
    end

    def executed?
      @executed
    end

    def static_errors
      validation_errors + analysis_errors + context.errors
    end

    # This is the operation to run for this query.
    # If more than one operation is present, it must be named at runtime.
    # @return [GraphQL::Language::Nodes::OperationDefinition, nil]
    def selected_operation
      with_prepared_ast { @selected_operation }
    end

    # Determine the values for variables of this query, using default values
    # if a value isn't provided at runtime.
    #
    # If some variable is invalid, errors are added to {#validation_errors}.
    #
    # @return [GraphQL::Query::Variables] Variables to apply to this query
    def variables
      @variables ||= begin
        with_prepared_ast {
          GraphQL::Query::Variables.new(
            @context,
            @ast_variables,
            @provided_variables,
          )
        }
      end
    end

    def irep_selection
      @selection ||= begin
        if selected_operation && internal_representation
          internal_representation.operation_definitions[selected_operation.name]
        else
          nil
        end
      end
    end

    # Node-level cache for calculating arguments. Used during execution and query analysis.
    # @param ast_node [GraphQL::Language::Nodes::AbstractNode]
    # @param definition [GraphQL::Schema::Field]
    # @param parent_object [GraphQL::Schema::Object]
    # @return Hash{Symbol => Object}
    def arguments_for(ast_node, definition, parent_object: nil)
      if interpreter?
        arguments_cache.fetch(ast_node, definition, parent_object)
      else
        arguments_cache[ast_node][definition]
      end
    end

    def arguments_cache
      if interpreter?
        @arguments_cache ||= Execution::Interpreter::ArgumentsCache.new(self)
      else
        @arguments_cache ||= ArgumentsCache.build(self)
      end
    end

    # A version of the given query string, with:
    # - Variables inlined to the query
    # - Strings replaced with `<REDACTED>`
    # @return [String, nil] Returns nil if the query is invalid.
    def sanitized_query_string(inline_variables: true)
      with_prepared_ast {
        GraphQL::Language::SanitizedPrinter.new(self, inline_variables: inline_variables).sanitized_query_string
      }
    end

    # This contains a few components:
    #
    # - The selected operation name (or `anonymous`)
    # - The fingerprint of the query string
    # - The number of given variables (for readability)
    # - The fingerprint of the given variables
    #
    # This fingerprint can be used to track runs of the same operation-variables combination over time.
    #
    # @see operation_fingerprint
    # @see variables_fingerprint
    # @return [String] An opaque hash identifying this operation-variables combination
    def fingerprint
      @fingerprint ||= "#{operation_fingerprint}/#{variables_fingerprint}"
    end

    # @return [String] An opaque hash for identifying this query's given query string and selected operation
    def operation_fingerprint
      @operation_fingerprint ||= "#{selected_operation_name || "anonymous"}/#{Fingerprint.generate(query_string)}"
    end

    # @return [String] An opaque hash for identifying this query's given a variable values (not including defaults)
    def variables_fingerprint
      @variables_fingerprint ||= "#{provided_variables.size}/#{Fingerprint.generate(provided_variables.to_json)}"
    end

    def validation_pipeline
      with_prepared_ast { @validation_pipeline }
    end

    def_delegators :validation_pipeline, :validation_errors, :internal_representation,
                   :analyzers, :ast_analyzers, :max_depth, :max_complexity

    attr_accessor :analysis_errors
    def valid?
      validation_pipeline.valid? && analysis_errors.empty?
    end

    def warden
      with_prepared_ast { @warden }
    end

    def_delegators :warden, :get_type, :get_field, :possible_types, :root_type_for_operation

    # @param abstract_type [GraphQL::UnionType, GraphQL::InterfaceType]
    # @param value [Object] Any runtime value
    # @return [GraphQL::ObjectType, nil] The runtime type of `value` from {Schema#resolve_type}
    # @see {#possible_types} to apply filtering from `only` / `except`
    def resolve_type(abstract_type, value = :__undefined__)
      if value.is_a?(Symbol) && value == :__undefined__
        # Old method signature
        value = abstract_type
        abstract_type = nil
      end
      if value.is_a?(GraphQL::Schema::Object)
        value = value.object
      end
      @resolved_types_cache[abstract_type][value]
    end

    def mutation?
      with_prepared_ast { @mutation }
    end

    def query?
      with_prepared_ast { @query }
    end

    # @return [void]
    def merge_filters(only: nil, except: nil)
      if @prepared_ast
        raise "Can't add filters after preparing the query"
      else
        @filter = @filter.merge(only: only, except: except)
      end
      nil
    end

    def subscription?
      with_prepared_ast { @subscription }
    end

    # @api private
    def with_error_handling
      schema.error_handler.with_error_handling(context) do
        yield
      end
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

    def prepare_ast
      @prepared_ast = true
      @warden ||= GraphQL::Schema::Warden.new(@filter, schema: @schema, context: @context)
      parse_error = nil
      @document ||= begin
        if query_string
          GraphQL.parse(query_string, tracer: self)
        end
      rescue GraphQL::ParseError => err
        parse_error = err
        @schema.parse_error(err, @context)
        nil
      end

      @fragments = {}
      @operations = {}
      if @document
        @document.definitions.each do |part|
          case part
          when GraphQL::Language::Nodes::FragmentDefinition
            @fragments[part.name] = part
          when GraphQL::Language::Nodes::OperationDefinition
            @operations[part.name] = part
          end
        end
      elsif parse_error
        # This will be handled later
      else
        parse_error = GraphQL::ExecutionError.new("No query string was present")
        @context.add_error(parse_error)
      end

      # Trying to execute a document
      # with no operations returns an empty hash
      @ast_variables = []
      @mutation = false
      @subscription = false
      operation_name_error = nil
      if @operations.any?
        @selected_operation = find_operation(@operations, @operation_name)
        if @selected_operation.nil?
          operation_name_error = GraphQL::Query::OperationNameMissingError.new(@operation_name)
        else
          if @operation_name.nil?
            @operation_name = @selected_operation.name
          end
          @ast_variables = @selected_operation.variables
          @mutation = @selected_operation.operation_type == "mutation"
          @query = @selected_operation.operation_type == "query"
          @subscription = @selected_operation.operation_type == "subscription"
        end
      end

      @validation_pipeline = GraphQL::Query::ValidationPipeline.new(
        query: self,
        validate: @validate,
        parse_error: parse_error,
        operation_name_error: operation_name_error,
        max_depth: @max_depth,
        max_complexity: @max_complexity
      )
    end

    # Since the query string is processed at the last possible moment,
    # any internal values which depend on it should be accessed within this wrapper.
    def with_prepared_ast
      if !@prepared_ast
        prepare_ast
      end
      yield
    end
  end
end
