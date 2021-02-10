# frozen_string_literal: true
module GraphQL
  class Query
    class Executor
      class PropagateNull < StandardError; end

      # @return [GraphQL::Query] the query being executed
      attr_reader :query

      def initialize(query)
        @query = query
      end

      # Evaluate {operation_name} on {query}.
      # Handle {GraphQL::ExecutionError}s by putting them in the "errors" key.
      # @return [Hash] A GraphQL response, with either a "data" key or an "errors" key
      def result
        execute
      rescue GraphQL::ExecutionError => err
        query.context.errors << err
        {"errors" => [err.to_h]}
      end

      private

      def execute
        operation = query.selected_operation
        return {} if operation.nil?

        op_type = operation.operation_type
        root_type = query.root_type_for_operation(op_type)
        execution_strategy_class = query.schema.execution_strategy_for_operation(op_type)
        execution_strategy = execution_strategy_class.new

        query.context.execution_strategy = execution_strategy
        data_result = begin
          execution_strategy.execute(operation, root_type, query)
        rescue PropagateNull
          nil
        end
        result = { "data" => data_result }
        error_result = query.context.errors.map(&:to_h)

        if error_result.any?
          result["errors"] = error_result
        end

        result
      end
    end
  end
end
