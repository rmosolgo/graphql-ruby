# frozen_string_literal: true
require "graphql/execution/interpreter/execution_errors"
require "graphql/execution/interpreter/trace"
require "graphql/execution/interpreter/visitor"

module GraphQL
  module Execution
    class Interpreter
      def initialize
        # A buffer shared by all queries running in this interpreter
        @lazies = []
      end
      # Support `Executor` :S
      def execute(_operation, _root_type, query)
        run_query(query)
      end

      def run_query(query)
        query.context.interpreter = true
        evaluate(query)
      end

      def self.use(schema_defn)
        # TODO encapsulate this in `use` ?
        schema_defn.query_execution_strategy(GraphQL::Execution::Interpreter)
        schema_defn.mutation_execution_strategy(GraphQL::Execution::Interpreter)
        schema_defn.subscription_execution_strategy(GraphQL::Execution::Interpreter)
      end

      def self.begin_multiplex(multiplex)
        multiplex.context[:interpreter_instance] ||= self.new
      end

      def self.begin_query(query, multiplex)
        interpreter =
          query.context.namespace(:interpreter)[:interpreter_instance] =
          multiplex.context[:interpreter_instance]
        interpreter.run_query(query)
        query
      end

      def self.finish_multiplex(_results, multiplex)
        interpreter = multiplex.context[:interpreter_instance]
        interpreter.sync_lazies
      end

      def self.finish_query(query)
        {
          "data" => query.context.namespace(:interpreter)[:interpreter_trace].final_value
        }
      end

      def evaluate(query)
        trace = Trace.new(query: query, lazies: @lazies)
        query.context.namespace(:interpreter)[:interpreter_trace] = trace
        query.trace("execute_query", {query: query}) do
          Visitor.new.visit(trace)
        end
      end

      def sync_lazies
        # @query.trace("execute_query_lazy", {query: @query}) do
          while @lazies.any?
            next_wave = @lazies.dup
            @lazies.clear
            # This will cause a side-effect with Trace#write
            next_wave.each(&:value)
          end
        # end
      end
    end
  end
end
