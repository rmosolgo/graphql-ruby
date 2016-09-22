require "graphql/query/arguments"
require "graphql/query/context"
require "graphql/query/executor"
require "graphql/query/literal_input"
require "graphql/query/serial_execution"
require "graphql/query/variables"
require "graphql/query/input_validation_result"
require "graphql/query/variable_validation_error"

module GraphQL
  # A combination of query string and {Schema} instance which can be reduced to a {#result}.
  class Query
    class OperationNameMissingError < GraphQL::ExecutionError
      def initialize(names)
        msg = "You must provide an operation name from: #{names.join(", ")}"
        super(msg)
      end
    end

    attr_reader :schema, :document, :context, :fragments, :operations, :root_value, :max_depth, :query_string

    # Prepare query `query_string` on `schema`
    # @param schema [GraphQL::Schema]
    # @param query_string [String]
    # @param context [#[]] an arbitrary hash of values which you can access in {GraphQL::Field#resolve}
    # @param variables [Hash] values for `$variables` in the query
    # @param validate [Boolean] if true, `query_string` will be validated with {StaticValidation::Validator}
    # @param operation_name [String] if the query string contains many operations, this is the one which should be executed
    # @param root_value [Object] the object used to resolve fields on the root type
    # @param max_depth [Numeric] the maximum number of nested selections allowed for this query (falls back to schema-level value)
    # @param max_complexity [Numeric] the maximum field complexity for this query (falls back to schema-level value)
    def initialize(schema, query_string = nil, document: nil, context: nil, variables: {}, validate: true, operation_name: nil, root_value: nil, max_depth: nil, max_complexity: nil)
      fail ArgumentError, "a query string or document is required" unless query_string || document

      @schema = schema
      @max_depth = max_depth || schema.max_depth
      @max_complexity = max_complexity || schema.max_complexity
      @query_analyzers = schema.query_analyzers.dup
      if @max_depth
        @query_analyzers << GraphQL::Analysis::MaxQueryDepth.new(@max_depth)
      end
      if @max_complexity
        @query_analyzers << GraphQL::Analysis::MaxQueryComplexity.new(@max_complexity)
      end
      @context = Context.new(query: self, values: context)
      @root_value = root_value
      @validate = validate
      @operation_name = operation_name
      @fragments = {}
      @operations = {}
      @provided_variables = variables
      @query_string = query_string
      @document = document || GraphQL.parse(query_string)
      @document.definitions.each do |part|
        if part.is_a?(GraphQL::Language::Nodes::FragmentDefinition)
          @fragments[part.name] = part
        elsif part.is_a?(GraphQL::Language::Nodes::OperationDefinition)
          @operations[part.name] = part
        else
          raise GraphQL::ExecutionError, "GraphQL query cannot contain a schema definition"
        end
      end

      @arguments_cache = Hash.new { |h, k| h[k] = {} }
      @validation_errors = []
      @analysis_errors = []
      @internal_representation = nil
      @was_validated = false
    end

    # Get the result for this query, executing it once
    def result
      @result ||= begin
        if !valid?
          all_errors = validation_errors + analysis_errors
          if all_errors.any?
            { "errors" => all_errors }
          else
            nil
          end
        else
          Executor.new(self).result
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
    # Raises if a non-null variable isn't provided at runtime.
    # @return [GraphQL::Query::Variables] Variables to apply to this query
    def variables
      @variables ||= GraphQL::Query::Variables.new(
        schema,
        selected_operation.variables,
        @provided_variables
      )
    end

    # @return [Hash<String, nil => GraphQL::InternalRepresentation::Node] Operation name -> Irep node pairs
    def internal_representation
      valid?
      @internal_representation
    end

    # TODO this should probably contain error instances, not hashes
    # @return [Array<Hash>] Static validation errors for the query string
    def validation_errors
      valid?
      @validation_errors
    end


    # TODO this should probably contain error instances, not hashes
    # @return [Array<Hash>] Errors for this particular query run (eg, exceeds max complexity)
    def analysis_errors
      valid?
      @analysis_errors
    end

    # Node-level cache for calculating arguments. Used during execution and query analysis.
    # @return [GraphQL::Query::Arguments] Arguments for this node, merging default values, literal values and query variables
    def arguments_for(irep_node, definition)
      @arguments_cache[irep_node][definition] ||= begin
        GraphQL::Query::LiteralInput.from_arguments(
          irep_node.ast_node.arguments,
          definition.arguments,
          self.variables
        )
      end
    end

    # @return [GraphQL::Language::Nodes::Document, nil]
    def selected_operation
      @selected_operation ||= find_operation(@operations, @operation_name)
    end

    def valid?
      if !@was_validated
        @was_validated = true
        @valid = if @validate
          document_valid? && query_possible? && query_valid?
        else
          true
        end
      end

      @valid
    end

    private

    # Assert that the passed-in query string is internally consistent
    def document_valid?
      validation_result = schema.static_validator.validate(self)
      @validation_errors = validation_result[:errors]
      @internal_representation = validation_result[:irep]
      @validation_errors.none?
    end

    # Given that the document is valid, do we have what we need to
    # execute the document this time?
    # - Is there an operation to run?
    # - Are all variables accounted for?
    def query_possible?
      !selected_operation.nil? && variables
      true
    rescue GraphQL::Query::OperationNameMissingError, GraphQL::Query::VariableValidationError => err
      @validation_errors << err.to_h
      false
    end

    # Given that we _could_ execute this query, _should_ we?
    # - Does it violate any query analyzers?
    def query_valid?
      @analysis_errors = begin
        if @query_analyzers.any?
          reduce_results = GraphQL::Analysis.analyze_query(self, @query_analyzers)
          reduce_results
          .flatten # accept n-dimensional array
          .select { |r| r.is_a?(GraphQL::AnalysisError) }
          .map(&:to_h)
        else
          []
        end
      end
      @analysis_errors.none?
    end

    def find_operation(operations, operation_name)
      if operations.length == 1
        operations.values.first
      elsif operations.length == 0
        nil
      elsif !operations.key?(operation_name)
        raise OperationNameMissingError, operations.keys
      else
        operations[operation_name]
      end
    end
  end
end
