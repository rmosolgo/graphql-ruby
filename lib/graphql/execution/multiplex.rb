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
        def run_all(schema, query_options, *rest)
          queries = query_options.map { |opts| GraphQL::Query.new(schema, nil, opts) }
          run_queries(schema, queries, *rest)
        end

        def run_queries(schema, queries, context: {})
          query_instrumenters = schema.instrumenters[:query]
          multiplex_instrumenters = schema.instrumenters[:multiplex]
          multiplex = self.new(schema: schema, queries: queries, context: context)

          # First, run multiplex instrumentation, then query instrumentation for each query
          multiplex_instrumenters.each { |i| i.before_multiplex(multiplex) }
          queries.each do |query|
            query_instrumenters.each { |i| i.before_query(query) }
          end

          # Then, do as much eager evaluation of the query as possible
          results = queries.map do |query|
            begin_query(query)
          end

          # Then, work through lazy results in a breadth-first way
          GraphQL::Execution::Lazy.resolve(results)

          # Then, find all errors and assign the result to the query object
          results.each_with_index.map do |data_result, idx|
            query = queries[idx]
            finish_query(data_result, query)
          end
        ensure
          # Finally, run teardown instrumentation for each query + the multiplex
          queries.each do |query|
            query_instrumenters.each { |i| i.after_query(query) }
          end
          multiplex_instrumenters.each { |i| i.after_multiplex(multiplex) }
        end

        private

        # @param query [GraphQL::Query]
        # @return [Hash] The initial result (may not be finished if there are lazy values)
        def begin_query(query)
          operation = query.selected_operation
          if operation.nil? || !query.valid?
            NO_OPERATION
          else
            begin
              op_type = operation.operation_type
              root_type = query.root_type_for_operation(op_type)
              GraphQL::Execution::Execute::ExecutionFunctions.resolve_selection(
                query.root_value,
                root_type,
                query.irep_selection,
                query.context,
                mutation: query.mutation?
              )
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
      end
    end
  end
end
