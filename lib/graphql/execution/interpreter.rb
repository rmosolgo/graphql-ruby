# frozen_string_literal: true
require "graphql/execution/interpreter/execution_errors"
require "graphql/execution/interpreter/hash_response"
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
          "data" => query.context.namespace(:interpreter)[:interpreter_trace].final_value
        }
      end

      def evaluate(query)
        query.context.interpreter = true
        # Although queries in a multiplex _share_ an Interpreter instance,
        # they also have another item of state, which is private to that query
        # in particular, assign it here:
        trace = Trace.new(query: query, lazies: @lazies, response: HashResponse.new)
        query.context.namespace(:interpreter)[:interpreter_trace] = trace
        query.trace("execute_query", {query: query}) do
          Visitor.new.visit(query, trace)
        end
        trace
      end

      def sync_lazies(query: nil, multiplex: nil)
        tracer = query || multiplex
        if query.nil? && multiplex.queries.length == 1
          query = multiplex.queries[0]
        end
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
