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
        trace = evaluate(query)
        sync_lazies(query: query)
        trace.final_value
      end

      def self.use(schema_defn)
        schema_defn.query_execution_strategy(GraphQL::Execution::Interpreter)
        schema_defn.mutation_execution_strategy(GraphQL::Execution::Interpreter)
        schema_defn.subscription_execution_strategy(GraphQL::Execution::Interpreter)
      end

      # TODO rename and reconsider these hooks.
      # Or, are they just temporary?
      def self.begin_multiplex(multiplex)
        multiplex.context[:interpreter_instance] ||= self.new
      end

      def self.begin_query(query, multiplex)
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

      def self.finish_query(query)
        {
          "data" => query.context.namespace(:interpreter)[:interpreter_trace].final_value
        }
      end

      def evaluate(query)
        query.context.interpreter = true
        trace = Trace.new(query: query, lazies: @lazies)
        query.context.namespace(:interpreter)[:interpreter_trace] = trace
        query.trace("execute_query", {query: query}) do
          Visitor.new.visit(trace)
        end
        trace
      end

      def sync_lazies(query: nil, multiplex: nil)
        tracer = query || multiplex
        tracer.trace("execute_query_lazy", {multiplex: multiplex, query: query}) do
          while @lazies.any?
            next_wave = @lazies.dup
            @lazies.clear
            # This will cause a side-effect with Trace#write
            next_wave.each(&:value)
          end
        end
      end
    end
  end
end
