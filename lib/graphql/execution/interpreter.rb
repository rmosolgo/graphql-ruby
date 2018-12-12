# frozen_string_literal: true
require "graphql/execution/interpreter/execution_errors"
require "graphql/execution/interpreter/hash_response"
require "graphql/execution/interpreter/runtime"

module GraphQL
  module Execution
    class Interpreter
      def initialize
      end

      # Support `Executor` :S
      def execute(_operation, _root_type, query)
        runtime = evaluate(query)
        sync_lazies(query: query)
        runtime.final_value
      end

      def self.use(schema_defn)
        schema_defn.target.interpreter = true
        # Reach through the legacy objects for the actual class defn
        schema_class = schema_defn.target.class
        # This is not good, since both of these are holding state now,
        # we have to update both :(
        [schema_class, schema_defn].each do |schema_config|
          schema_config.query_execution_strategy(GraphQL::Execution::Interpreter)
          schema_config.mutation_execution_strategy(GraphQL::Execution::Interpreter)
          schema_config.subscription_execution_strategy(GraphQL::Execution::Interpreter)
        end
      end

      def self.begin_multiplex(multiplex)
        # Since this is basically the batching context,
        # share it for a whole multiplex
        multiplex.context[:interpreter_instance] ||= self.new
      end

      def self.begin_query(query, multiplex)
        # The batching context is shared by the multiplex,
        # so fetch it out and use that instance.
        interpreter =
          query.context.namespace(:interpreter)[:interpreter_instance] =
          multiplex.context[:interpreter_instance]
        interpreter.evaluate(query)
        query
      end

      def self.finish_multiplex(_results, multiplex)
        interpreter = multiplex.context[:interpreter_instance]
        interpreter.sync_lazies(multiplex: multiplex)
      end

      def self.finish_query(query, _multiplex)
        {
          "data" => query.context.namespace(:interpreter)[:runtime].final_value
        }
      end

      # Run the eager part of `query`
      # @return {Interpreter::Runtime}
      def evaluate(query)
        # Although queries in a multiplex _share_ an Interpreter instance,
        # they also have another item of state, which is private to that query
        # in particular, assign it here:
        runtime = Runtime.new(
          query: query,
          response: HashResponse.new,
        )
        query.context.namespace(:interpreter)[:runtime] = runtime

        query.trace("execute_query", {query: query}) do
          runtime.run_eager
        end

        runtime
      end

      # Run the lazy part of `query` or `multiplex`.
      # @return [void]
      def sync_lazies(query: nil, multiplex: nil)
        tracer = query || multiplex
        if query.nil? && multiplex.queries.length == 1
          query = multiplex.queries[0]
        end
        queries = multiplex ? multiplex.queries : [query]
        final_values = queries.map do |query|
          runtime = query.context.namespace(:interpreter)[:runtime]
          # it might not be present if the query has an error
          runtime ? runtime.final_value : nil
        end
        final_values.compact!
        tracer.trace("execute_query_lazy", {multiplex: multiplex, query: query}) do
          while final_values.any?
            final_values = resolve_interpreter_result(final_values)
          end
        end
      end

      private

      # `results_level` is one level of _depth_ of a query or multiplex.
      #
      # Resolve all lazy values in that depth before moving on
      # to the next level.
      #
      # It's assumed that the lazies will perform side-effects
      # and return {Lazy} instances if there's more work to be done,
      # or return {Hash}/{Array} if the query should be continued.
      #
      # @param result [Array, Hash, Object]
      # @return void
      def resolve_interpreter_result(results_level)
        next_level = []

        # Work through the queue until it's empty
        while results_level.size > 0
          result_value = results_level.shift

          if result_value.is_a?(Lazy)
            result_value = result_value.value
          end

          if result_value.is_a?(Lazy)
            # Since this field returned another lazy,
            # add it to the same queue
            results_level << result_value
          elsif result_value.is_a?(Hash)
            # This is part of the next level, add it
            next_level.concat(result_value.values)
          elsif result_value.is_a?(Array)
            # This is part of the next level, add it
            next_level.concat(result_value)
          end
        end

        next_level
      end
    end
  end
end
