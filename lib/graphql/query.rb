# frozen_string_literal: true
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
    extend Forwardable

    class OperationNameMissingError < GraphQL::ExecutionError
      def initialize(names)
        msg = "You must provide an operation name from: #{names.join(", ")}"
        super(msg)
      end
    end

    attr_reader :schema, :document, :context, :fragments, :operations, :root_value, :max_depth, :query_string, :warden, :provided_variables

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
      mask = MergedMask.combine(schema.default_mask, except: except, only: only)
      @context = Context.new(query: self, values: context)
      @warden = GraphQL::Schema::Warden.new(mask, schema: @schema, context: @context)
      @max_depth = max_depth || schema.max_depth
      @max_complexity = max_complexity || schema.max_complexity
      @query_analyzers = schema.query_analyzers.dup
      if @max_depth
        @query_analyzers << GraphQL::Analysis::MaxQueryDepth.new(@max_depth)
      end
      if @max_complexity
        @query_analyzers << GraphQL::Analysis::MaxQueryComplexity.new(@max_complexity)
      end
      @root_value = root_value
      @operation_name = operation_name
      @fragments = {}
      @operations = {}
      if variables.is_a?(String)
        raise ArgumentError, "Query variables should be a Hash, not a String. Try JSON.parse to prepare variables."
      else
        @provided_variables = variables
      end
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

      @resolved_types_cache = Hash.new { |h, k| h[k] = @schema.resolve_type(k, @context) }

      @arguments_cache = Hash.new { |h, k| h[k] = {} }
      @validation_errors = []
      @analysis_errors = []
      @internal_representation = nil
      @was_validated = false

      # Trying to execute a document
      # with no operations returns an empty hash
      @ast_variables = []
      @mutation = false
      if @operations.any?
        @selected_operation = find_operation(@operations, @operation_name)
        if @selected_operation.nil?
          @validation_errors << GraphQL::Query::OperationNameMissingError.new(@operations.keys)
        else
          @ast_variables = @selected_operation.variables
          @mutation = @selected_operation.operation_type == "mutation"
        end
      end
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
            all_errors = validation_errors + analysis_errors
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
          @schema,
          @warden,
          @ast_variables,
          @provided_variables,
        )
        @validation_errors.concat(vars.errors)
        vars
      end
    end

    # @return [Hash<String, nil => GraphQL::InternalRepresentation::Node] Operation name -> Irep node pairs
    def internal_representation
      valid?
      @internal_representation
    end

    def irep_selection
      @selection ||= begin
        root_type = schema.root_type_for_operation(selected_operation.operation_type)
        internal_representation[root_type][selected_operation.name]
      end
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
        ast_node = case irep_node
        when GraphQL::Language::Nodes::AbstractNode
          irep_node
        else
          irep_node.ast_node
        end
        ast_arguments = ast_node.arguments
        if ast_arguments.none?
          definition.default_arguments
        else
          GraphQL::Query::LiteralInput.from_arguments(
            ast_arguments,
            definition.arguments,
            self.variables
          )
        end
      end
    end

    # @return [GraphQL::Language::Nodes::Document, nil]
    attr_reader :selected_operation

    def valid?
      @was_validated ||= begin
        @was_validated = true
        @valid = document_valid? && query_valid? && variables.errors.none?
        true
      end

      @valid
    end

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

    # Assert that the passed-in query string is internally consistent
    def document_valid?
      validation_result = schema.static_validator.validate(self)
      @validation_errors.concat(validation_result[:errors])
      @internal_representation = validation_result[:irep]
      @validation_errors.none?
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
        else
          []
        end
      end
      @analysis_errors.none?
    end

    def find_operation(operations, operation_name)
      if operations.length == 1
        operations.values.first
      elsif operations.length == 0 || !operations.key?(operation_name)
        nil
      else
        operations[operation_name]
      end
    end

    # @api private
    class InvertedMask
      def initialize(inner_mask)
        @inner_mask = inner_mask
      end

      # Returns true when the inner mask returned false
      # Returns false when the inner mask returned true
      def call(member, ctx)
        !@inner_mask.call(member, ctx)
      end
    end

    # @api private
    class LegacyMaskWrap
      def initialize(inner_mask)
        @inner_mask = inner_mask
      end

      def call(member, ctx)
        @inner_mask.call(member)
      end
    end

    # @api private
    class MergedMask
      def initialize(first_mask, second_mask)
        @first_mask = first_mask
        @second_mask = second_mask
      end

      def call(member, ctx)
        @first_mask.call(member, ctx) || @second_mask.call(member, ctx)
      end

      def self.combine(default_mask, except:, only:)
        query_mask = if except
          wrap_if_legacy_mask(except)
        elsif only
          InvertedMask.new(wrap_if_legacy_mask(only))
        end

        if query_mask && (default_mask != GraphQL::Schema::NullMask)
          self.new(default_mask, query_mask)
        else
          query_mask || default_mask
        end
      end

      def self.wrap_if_legacy_mask(mask)
        if (mask.is_a?(Proc) && mask.arity == 1) || mask.method(:call).arity == 1
          warn("Schema.execute(..., except:) filters now accept two arguments, `(member, ctx)`. One-argument filters are deprecated.")
          LegacyMaskWrap.new(mask)
        else
          mask
        end
      end
    end
  end
end
