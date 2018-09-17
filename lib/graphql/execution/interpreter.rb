# frozen_string_literal: true
require "graphql/execution/interpreter/execution_errors"
require "graphql/execution/interpreter/trace"
require "graphql/execution/interpreter/visitor"

module GraphQL
  module Execution
    class Interpreter
      # This method is the Executor API
      # TODO revisit Executor's reason for living.
      def execute(_ast_operation, _root_type, query)
        query.context[:__temp_running_interpreter] = true
        @query = query
        @schema = query.schema
        evaluate
      end

      def evaluate
        trace = Trace.new(query: @query)
        trace.visitor.visit
        while trace.lazies.any?
          next_wave = trace.lazies.dup
          trace.lazies.clear
          # This will cause a side-effect with Trace#write
          next_wave.each(&:value)
        end
        trace.result
      rescue
        # puts $!.message
        # puts trace.inspect
        # puts $!.backtrace
        raise
      end
    end
  end
end
