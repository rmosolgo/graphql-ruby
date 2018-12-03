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
        evaluate(query)
        sync_lazies(query: query)
        runtime = query.context.namespace(:interpreter)[:runtime]
        runtime.final_value
      end

      def self.use(schema_defn)
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

      def evaluate(query)
        query.context.interpreter = true
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

        nil
      end

      def sync_lazies(query: nil, multiplex: nil)
        tracer = query || multiplex
        if query.nil? && multiplex.queries.length == 1
          query = multiplex.queries[0]
        end
        queries = multiplex ? multiplex.queries : [query]
        final_values = queries.map { |q| q.context.namespace(:interpreter)[:runtime].final_value }
        tracer.trace("execute_query_lazy", {multiplex: multiplex, query: query}) do
          resolve_interpreter_result(final_values)
        end
      end

      private

      # `result` is one level of _depth_ of a query or multiplex.
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
      def resolve_interpreter_result(result)
        next_level = case result
        when Array
          result
        when Hash
          result.values
        when Lazy
          [result]
        else
          []
        end

        next_non_lazy_values = []
        next_level.each do |next_value|
          if next_value.is_a?(Lazy)
            next_value = next_value.value
          end

          if next_value.is_a?(Lazy)
            next_level << next_value
          elsif next_value.is_a?(Hash)
            next_non_lazy_values.concat(next_value.values)
          elsif next_value.is_a?(Array)
            next_non_lazy_values.concat(next_value)
          end
        end

        if next_non_lazy_values.any?
          resolve_interpreter_result(next_non_lazy_values)
        end
      end
    end
  end
end
