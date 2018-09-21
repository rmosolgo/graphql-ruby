# frozen_string_literal: true
require "graphql/execution/interpreter/execution_errors"
require "graphql/execution/interpreter/trace"
require "graphql/execution/interpreter/visitor"

module GraphQL
  module Execution
    class Interpreter
      def run_query(query)
        query.context[:__temp_running_interpreter] = true
        @query = query
        @schema = query.schema
        evaluate
      end

      def self.use(schema_defn)
        # TODO encapsulate this in `use` ?
        schema_defn.query_execution_strategy(GraphQL::Execution::Interpreter)
        schema_defn.mutation_execution_strategy(GraphQL::Execution::Interpreter)
        schema_defn.subscription_execution_strategy(GraphQL::Execution::Interpreter)
      end

      def self.begin_multiplex(query)
        self.new.run_query(query)
      end

      def self.finish_multiplex(results, multiplex)
        # TODO isolate promise loading here
      end

      def evaluate
        trace = Trace.new(query: @query)
        @query.trace("execute_query", {query: @query}) do
          Visitor.new.visit(trace)
        end

        @query.trace("execute_query_lazy", {query: @query}) do
          while trace.lazies.any?
            next_wave = trace.lazies.dup
            trace.lazies.clear
            # This will cause a side-effect with Trace#write
            next_wave.each(&:value)
          end

          # TODO This is to satisfy Execution::Flatten, which should be removed
          @query.context.value = trace.final_value
        end
      rescue
        puts $!.message
        puts trace.inspect
        raise
      end
    end
  end
end
