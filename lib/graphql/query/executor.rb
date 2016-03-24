module GraphQL
  class Query
    class Executor
      # @return [GraphQL::Query] the query being executed
      attr_reader :query

      def initialize(query)
        @query = query
      end

      # Evalute {operation_name} on {query}. Handle errors by putting them in the "errors" key.
      # (Or, if `query.debug`, by re-raising them.)
      # @return [Hash] A GraphQL response, with either a "data" key or an "errors" key
      def result
        execute
      rescue GraphQL::ExecutionError => err
        query.context.errors << err
        {"errors" => [err.to_h]}
      rescue StandardError => err
        query.context.errors << err
        query.debug && raise(err)
        message = "Internal error" #\n#{err.backtrace.join("\n  ")}"
        {"errors" => [{"message" => message}]}
      end

      private

      def execute
        operation = query.selected_operation
        return {} if operation.nil?

        op_type = operation.operation_type
        root_type = query.schema.public_send(op_type)
        execution_strategy_class = query.schema.public_send("#{op_type}_execution_strategy")
        execution_strategy = execution_strategy_class.new

        query.context.execution_strategy = execution_strategy
        data_result = execution_strategy.execute(operation, root_type, query)
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
