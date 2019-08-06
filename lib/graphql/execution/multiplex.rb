# frozen_string_literal: true
module GraphQL
  module Execution
    # Execute multiple queries under the same multiplex "umbrella".
    # They can share a batching context and reduce redundant database hits.
    #
    # The flow is:
    #
    # - Multiplex instrumentation setup
    # - Query instrumentation setup
    # - Analyze the multiplex + each query
    # - Begin each query
    # - Resolve lazy values, breadth-first across all queries
    # - Finish each query (eg, get errors)
    # - Query instrumentation teardown
    # - Multiplex instrumentation teardown
    #
    # If one query raises an application error, all queries will be in undefined states.
    #
    # Validation errors and {GraphQL::ExecutionError}s are handled in isolation:
    # one of these errors in one query will not affect the other queries.
    #
    # @see {Schema#multiplex} for public API
    # @api private
    class Multiplex
      # Used internally to signal that the query shouldn't be executed
      # @api private
      NO_OPERATION = {}.freeze

      include Tracing::Traceable

      attr_reader :context, :queries, :schema, :max_complexity
      def initialize(schema:, queries:, context:, max_complexity:)
        @schema = schema
        @queries = queries
        @context = context
        # TODO remove support for global tracers
        @tracers = schema.tracers + GraphQL::Tracing.tracers + (context[:tracers] || [])
        # Support `context: {backtrace: true}`
        if context[:backtrace] && !@tracers.include?(GraphQL::Backtrace::Tracer)
          @tracers << GraphQL::Backtrace::Tracer
        end
        @max_complexity = max_complexity
      end

      class << self
        def run_all(schema, query_options, *args)
          queries = query_options.map { |opts| GraphQL::Query.new(schema, nil, opts) }
          run_queries(schema, queries, *args)
        end

        # @param schema [GraphQL::Schema]
        # @param queries [Array<GraphQL::Query>]
        # @param context [Hash]
        # @param max_complexity [Integer, nil]
        # @return [Array<Hash>] One result per query
        def run_queries(schema, queries, context: {}, max_complexity: schema.max_complexity)
          multiplex = self.new(schema: schema, queries: queries, context: context, max_complexity: max_complexity)
          multiplex.trace("execute_multiplex", { multiplex: multiplex }) do
            if supports_multiplexing?(schema)
              instrument_and_analyze(multiplex) do
                run_as_multiplex(multiplex)
              end
            else
              if queries.length != 1
                raise ArgumentError, "Multiplexing doesn't support custom execution strategies, run one query at a time instead"
              else
                instrument_and_analyze(multiplex) do
                  [run_one_legacy(schema, queries.first)]
                end
              end
            end
          end
        end

        private

        def run_as_multiplex(multiplex)

          multiplex.schema.query_execution_strategy.begin_multiplex(multiplex)
          queries = multiplex.queries
          # Do as much eager evaluation of the query as possible
          results = queries.map do |query|
            begin_query(query, multiplex)
          end

          # Then, work through lazy results in a breadth-first way
          multiplex.schema.query_execution_strategy.finish_multiplex(results, multiplex)

          # Then, find all errors and assign the result to the query object
          results.each_with_index.map do |data_result, idx|
            query = queries[idx]
            finish_query(data_result, query, multiplex)
            # Get the Query::Result, not the Hash
            query.result
          end
        rescue Exception
          # Assign values here so that the query's `@executed` becomes true
          queries.map { |q| q.result_values ||= {} }
          raise
        end

        # @param query [GraphQL::Query]
        # @return [Hash] The initial result (may not be finished if there are lazy values)
        def begin_query(query, multiplex)
          operation = query.selected_operation
          if operation.nil? || !query.valid? || query.context.errors.any?
            NO_OPERATION
          else
            begin
              # These were checked to be the same in `#supports_multiplexing?`
              query.schema.query_execution_strategy.begin_query(query, multiplex)
            rescue GraphQL::ExecutionError => err
              query.context.errors << err
              NO_OPERATION
            end
          end
        end

        # @param data_result [Hash] The result for the "data" key, if any
        # @param query [GraphQL::Query] The query which was run
        # @return [Hash] final result of this query, including all values and errors
        def finish_query(data_result, query, multiplex)
          # Assign the result so that it can be accessed in instrumentation
          query.result_values = if data_result.equal?(NO_OPERATION)
            if !query.valid? || query.context.errors.any?
              # A bit weird, but `Query#static_errors` _includes_ `query.context.errors`
              { "errors" => query.static_errors.map(&:to_h) }
            else
              data_result
            end
          else
            # Use `context.value` which was assigned during execution
            result = query.schema.query_execution_strategy.finish_query(query, multiplex)

            if query.context.errors.any?
              error_result = query.context.errors.map(&:to_h)
              result["errors"] = error_result
            end

            result
          end
        end

        # use the old `query_execution_strategy` etc to run this query
        def run_one_legacy(schema, query)
          query.result_values = if !query.valid?
            all_errors = query.validation_errors + query.analysis_errors + query.context.errors
            if all_errors.any?
              { "errors" => all_errors.map(&:to_h) }
            else
              nil
            end
          else
            GraphQL::Query::Executor.new(query).result
          end
        end

        DEFAULT_STRATEGIES = [
          GraphQL::Execution::Execute,
          GraphQL::Execution::Interpreter
        ]
        # @return [Boolean] True if the schema is only using one strategy, and it's one that supports multiplexing.
        def supports_multiplexing?(schema)
          schema_strategies = [schema.query_execution_strategy, schema.mutation_execution_strategy, schema.subscription_execution_strategy]
          schema_strategies.uniq!
          schema_strategies.size == 1 && DEFAULT_STRATEGIES.include?(schema_strategies.first)
        end

        # Apply multiplex & query instrumentation to `queries`.
        #
        # It yields when the queries should be executed, then runs teardown.
        def instrument_and_analyze(multiplex)
          GraphQL::Execution::Instrumentation.apply_instrumenters(multiplex) do
            schema = multiplex.schema
            multiplex_analyzers = schema.multiplex_analyzers
            if multiplex.max_complexity
              multiplex_analyzers += if schema.using_ast_analysis?
                [GraphQL::Analysis::AST::MaxQueryComplexity]
              else
                [GraphQL::Analysis::MaxQueryComplexity.new(multiplex.max_complexity)]
              end
            end

            schema.analysis_engine.analyze_multiplex(multiplex, multiplex_analyzers)
            yield
          end
        end
      end
    end
  end
end
