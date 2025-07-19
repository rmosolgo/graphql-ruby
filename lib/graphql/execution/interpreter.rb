# frozen_string_literal: true
require "fiber"
require "graphql/execution/interpreter/argument_value"
require "graphql/execution/interpreter/arguments"
require "graphql/execution/interpreter/arguments_cache"
require "graphql/execution/interpreter/execution_errors"
require "graphql/execution/interpreter/runtime"
require "graphql/execution/interpreter/resolve"
require "graphql/execution/interpreter/handles_raw_value"

module GraphQL
  module Execution
    class Interpreter
      class << self
        # Used internally to signal that the query shouldn't be executed
        # @api private
        NO_OPERATION = GraphQL::EmptyObjects::EMPTY_HASH

        # @param schema [GraphQL::Schema]
        # @param queries [Array<GraphQL::Query, Hash>]
        # @param context [Hash]
        # @param max_complexity [Integer, nil]
        # @return [Array<GraphQL::Query::Result>] One result per query
        def run_all(schema, query_options, context: {}, max_complexity: schema.max_complexity)
          lazies_at_depth = Hash.new { |h, k| h[k] = [] }
          queries = query_options.map do |opts|
            query = case opts
            when Hash
              schema.query_class.new(schema, nil, **opts)
            when GraphQL::Query, GraphQL::Query::Partial
              opts
            else
              raise "Expected Hash or GraphQL::Query, not #{opts.class} (#{opts.inspect})"
            end
            query
          end

          return GraphQL::EmptyObjects::EMPTY_ARRAY if queries.empty?

          multiplex = Execution::Multiplex.new(schema: schema, queries: queries, context: context, max_complexity: max_complexity)
          trace = multiplex.current_trace
          Fiber[:__graphql_current_multiplex] = multiplex
          trace.execute_multiplex(multiplex: multiplex) do
            queries = multiplex.queries
            queries.each { |query| query.init_runtime(lazies_at_depth: lazies_at_depth) }
            schema = multiplex.schema
            multiplex_analyzers = schema.multiplex_analyzers
            if multiplex.max_complexity
              multiplex_analyzers += [GraphQL::Analysis::MaxQueryComplexity]
            end

            trace.begin_analyze_multiplex(multiplex, multiplex_analyzers)
            schema.analysis_engine.analyze_multiplex(multiplex, multiplex_analyzers)
            trace.end_analyze_multiplex(multiplex, multiplex_analyzers)

            begin
              # Since this is basically the batching context,
              # share it for a whole multiplex
              multiplex.context[:interpreter_instance] ||= multiplex.schema.query_execution_strategy(deprecation_warning: false).new
              # Do as much eager evaluation of the query as possible
              results = []
              queries.each_with_index do |query, idx|
                if query.subscription? && !query.subscription_update?
                  subs_namespace = query.context.namespace(:subscriptions)
                  subs_namespace[:events] = []
                  subs_namespace[:subscriptions] = {}
                end
                multiplex.dataloader.append_job {
                  operation = query.selected_operation
                  result = if operation.nil? || !query.valid? || !query.context.errors.empty?
                    NO_OPERATION
                  else
                    begin
                      query.current_trace.execute_query(query: query) do
                        query.context.runtime.run_eager
                      end
                    rescue GraphQL::ExecutionError => err
                      query.context.errors << err
                      NO_OPERATION
                    end
                  end
                  results[idx] = result
                }
              end

              multiplex.dataloader.run

              # Then, work through lazy results in a breadth-first way
              multiplex.dataloader.append_job {
                query = multiplex.queries.length == 1 ? multiplex.queries[0] : nil
                multiplex.current_trace.execute_query_lazy(multiplex: multiplex, query: query) do
                  Interpreter::Resolve.resolve_each_depth(lazies_at_depth, multiplex.dataloader)
                end
              }
              multiplex.dataloader.run

              # Then, find all errors and assign the result to the query object
              results.each_with_index do |data_result, idx|
                query = queries[idx]
                if (events = query.context.namespace(:subscriptions)[:events]) && !events.empty?
                  schema.subscriptions.write_subscription(query, events)
                end
                # Assign the result so that it can be accessed in instrumentation
                query.result_values = if data_result.equal?(NO_OPERATION)
                  if !query.valid? || !query.context.errors.empty?
                    # A bit weird, but `Query#static_errors` _includes_ `query.context.errors`
                    { "errors" => query.static_errors.map(&:to_h) }
                  else
                    data_result
                  end
                else
                  result = {}

                  if !query.context.errors.empty?
                    error_result = query.context.errors.map(&:to_h)
                    result["errors"] = error_result
                  end

                  result["data"] = query.context.namespace(:interpreter_runtime)[:runtime].final_result

                  result
                end
                if query.context.namespace?(:__query_result_extensions__)
                  query.result_values["extensions"] = query.context.namespace(:__query_result_extensions__)
                end
                # Get the Query::Result, not the Hash
                results[idx] = query.result
              end

              results
            rescue Exception
              # TODO rescue at a higher level so it will catch errors in analysis, too
              # Assign values here so that the query's `@executed` becomes true
              queries.map { |q| q.result_values ||= {} }
              raise
            ensure
              Fiber[:__graphql_current_multiplex] = nil
              queries.map { |query|
                runtime = query.context.namespace(:interpreter_runtime)[:runtime]
                if runtime
                  runtime.delete_all_interpreter_context
                end
              }
            end
          end
        end
      end

      class ListResultFailedError < GraphQL::Error
        def initialize(value:, path:, field:)
          message = "Failed to build a GraphQL list result for field `#{field.path}` at path `#{path.join(".")}`.\n".dup

          message << "Expected `#{value.inspect}` (#{value.class}) to implement `.each` to satisfy the GraphQL return type `#{field.type.to_type_signature}`.\n"

          if field.connection?
            message << "\nThis field was treated as a Relay-style connection; add `connection: false` to the `field(...)` to disable this behavior."
          end
          super(message)
        end
      end
    end
  end
end
