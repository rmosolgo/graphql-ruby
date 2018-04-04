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

      attr_reader :context, :queries, :schema
      def initialize(schema:, queries:, context:)
        @schema = schema
        @queries = queries
        @context = context
        # TODO remove support for global tracers
        @tracers = schema.tracers + GraphQL::Tracing.tracers + (context[:tracers] || [])
        # Support `context: {backtrace: true}`
        if context[:backtrace] && !@tracers.include?(GraphQL::Backtrace::Tracer)
          @tracers << GraphQL::Backtrace::Tracer
        end
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
          multiplex = self.new(schema: schema, queries: queries, context: context)
          multiplex.trace("execute_multiplex", { multiplex: multiplex }) do
            if has_custom_strategy?(schema)
              if queries.length != 1
                raise ArgumentError, "Multiplexing doesn't support custom execution strategies, run one query at a time instead"
              else
                instrument_and_analyze(multiplex, max_complexity: max_complexity) do
                  [run_one_legacy(schema, queries.first)]
                end
              end
            else
              instrument_and_analyze(multiplex, max_complexity: max_complexity) do
                run_as_multiplex(multiplex)
              end
            end
          end
        end

        private

        def run_as_multiplex(multiplex)
          queries = multiplex.queries
          # Do as much eager evaluation of the query as possible
          results = queries.map do |query|
            begin_query(query)
          end

          # Then, work through lazy results in a breadth-first way
          GraphQL::Execution::Execute::ExecutionFunctions.lazy_resolve_root_selection(results, { multiplex: multiplex })

          # Then, find all errors and assign the result to the query object
          results.each_with_index.map do |data_result, idx|
            query = queries[idx]
            finish_query(data_result, query)
            # Get the Query::Result, not the Hash
            query.result
          end
        rescue StandardError
          # Assign values here so that the query's `@executed` becomes true
          queries.map { |q| q.result_values ||= {} }
          raise
        end

        # @param query [GraphQL::Query]
        # @return [Hash] The initial result (may not be finished if there are lazy values)
        def begin_query(query)
          operation = query.selected_operation
          if operation.nil? || !query.valid?
            NO_OPERATION
          else
            begin
              GraphQL::Execution::Execute::ExecutionFunctions.resolve_root_selection(query)
            rescue GraphQL::ExecutionError => err
              query.context.errors << err
              NO_OPERATION
            end
          end
        end

        # @param data_result [Hash] The result for the "data" key, if any
        # @param query [GraphQL::Query] The query which was run
        # @return [Hash] final result of this query, including all values and errors
        def finish_query(data_result, query)
          # Assign the result so that it can be accessed in instrumentation
          query.result_values = if data_result.equal?(NO_OPERATION)
            if !query.valid?
              { "errors" => query.static_errors.map(&:to_h) }
            else
              data_result
            end
          else
            # Use `context.value` which was assigned during execution
            result = {
              "data" => Execution::Flatten.call(query.context)
            }

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

        def has_custom_strategy?(schema)
          schema.query_execution_strategy != GraphQL::Execution::Execute ||
            schema.mutation_execution_strategy != GraphQL::Execution::Execute ||
            schema.subscription_execution_strategy != GraphQL::Execution::Execute
        end

        # Apply multiplex & query instrumentation to `queries`.
        #
        # It yields when the queries should be executed, then runs teardown.
        def instrument_and_analyze(multiplex, max_complexity:)
          GraphQL::Execution::Instrumentation.apply_instrumenters(multiplex) do
            schema = multiplex.schema
            multiplex_analyzers = schema.multiplex_analyzers
            if max_complexity
              multiplex_analyzers += [GraphQL::Analysis::MaxQueryComplexity.new(max_complexity)]
            end

            GraphQL::Analysis.analyze_multiplex(multiplex, multiplex_analyzers)
            yield
          end
        end
      end
    end
  end
end
