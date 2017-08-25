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

      attr_reader :context, :queries, :schema
      def initialize(schema:, queries:, context:)
        @schema = schema
        @queries = queries
        @context = context
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

          if has_custom_strategy?(schema)
            if queries.length != 1
              raise ArgumentError, "Multiplexing doesn't support custom execution strategies, run one query at a time instead"
            else
              with_instrumentation(schema, queries, context: context, max_complexity: max_complexity) do
                [run_one_legacy(schema, queries.first)]
              end
            end
          else
            with_instrumentation(schema, queries, context: context, max_complexity: max_complexity) do
              run_as_multiplex(queries)
            end
          end
        end

        private

        def run_as_multiplex(queries)
          # Do as much eager evaluation of the query as possible
          results = queries.map do |query|
            begin_query(query)
          end

          # Then, work through lazy results in a breadth-first way
          GraphQL::Execution::Execute::ExecutionFunctions.lazy_resolve_root_selection(results, { queries: queries })

          # Then, find all errors and assign the result to the query object
          results.each_with_index.map do |data_result, idx|
            query = queries[idx]
            finish_query(data_result, query)
          end
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
              {}
            end
          end
        end

        # @param data_result [Hash] The result for the "data" key, if any
        # @param query [GraphQL::Query] The query which was run
        # @return [Hash] final result of this query, including all values and errors
        def finish_query(data_result, query)
          # Assign the result so that it can be accessed in instrumentation
          query.result = if data_result.equal?(NO_OPERATION)
            if !query.valid?
              { "errors" => query.static_errors.map(&:to_h) }
            else
              {}
            end
          else
            result = { "data" => data_result.to_h }
            error_result = query.context.errors.map(&:to_h)

            if error_result.any?
              result["errors"] = error_result
            end

            result
          end
        end

        # use the old `query_execution_strategy` etc to run this query
        def run_one_legacy(schema, query)
          query.result = if !query.valid?
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
        def with_instrumentation(schema, queries, context:, max_complexity:)
          query_instrumenters = schema.instrumenters[:query]
          multiplex_instrumenters = schema.instrumenters[:multiplex]
          multiplex = self.new(schema: schema, queries: queries, context: context)

          # First, run multiplex instrumentation, then query instrumentation for each query
          multiplex_instrumenters.each { |i| i.before_multiplex(multiplex) }
          queries.each do |query|
            query_instrumenters.each { |i| i.before_query(query) }
          end

          multiplex_analyzers = schema.multiplex_analyzers
          if max_complexity
            multiplex_analyzers += [GraphQL::Analysis::MaxQueryComplexity.new(max_complexity)]
          end

          GraphQL::Analysis.analyze_multiplex(multiplex, multiplex_analyzers)

          # Let them be executed
          yield
        ensure
          # Finally, run teardown instrumentation for each query + the multiplex
          # Use `reverse_each` so instrumenters are treated like a stack
          queries.each do |query|
            query_instrumenters.reverse_each { |i| i.after_query(query) }
          end
          multiplex_instrumenters.reverse_each { |i| i.after_multiplex(multiplex) }
        end
      end
    end
  end
end
