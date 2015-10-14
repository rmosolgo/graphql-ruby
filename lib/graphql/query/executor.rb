module GraphQL
  class Query
    class Executor
      # @return [GraphQL::Query] the query being executed
      attr_reader :query

      # @return [String] the operation to run in {query}
      attr_reader :operation_name


      def initialize(query, operation_name)
        @query = query
        @operation_name = operation_name
      end

      # Evalute {operation_name} on {query}. Handle errors by putting them in the "errors" key.
      # (Or, if `query.debug`, by re-raising them.)
      # @return [Hash] A GraphQL response, with either a "data" key or an "errors" key
      def result
        execute
      rescue GraphQL::Query::OperationNameMissingError => err
        {"errors" => [{"message" => err.message}]}
      rescue StandardError => err
        query.debug && raise(err)
        message = "Something went wrong during query execution: #{err}" #\n#{err.backtrace.join("\n  ")}"
        {"errors" => [{"message" => message}]}
      end

      private

      def execute
        operation = query.selected_operation
        return {} if operation.nil?

        if operation.operation_type == "query"
          root_type = query.schema.query
          execution_strategy_class = query.schema.query_execution_strategy
        elsif operation.operation_type == "mutation"
          root_type = query.schema.mutation
          execution_strategy_class = query.schema.mutation_execution_strategy
        end
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
