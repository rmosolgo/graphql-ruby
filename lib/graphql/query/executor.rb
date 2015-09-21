module GraphQL
  class Query
    class Executor
      class OperationNameMissingError < StandardError
        def initialize(names)
          msg = "You must provide an operation name from: #{names.join(", ")}"
          super(msg)
        end
      end

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
        {"data" => execute }
      rescue OperationNameMissingError => err
        {"errors" => [{"message" => err.message}]}
      rescue StandardError => err
        query.debug && raise(err)
        message = "Something went wrong during query execution: #{err}" # \n  #{err.backtrace.join("\n  ")}"
        {"errors" => [{"message" => message}]}
      end

      private

      def execute
        return {} if query.operations.none?
        operation = find_operation(operation_name, query.operations)
        if operation.operation_type == "query"
          root_type = query.schema.query
          execution_strategy_class = query.schema.query_execution_strategy
        elsif operation.operation_type == "mutation"
          root_type = query.schema.mutation
          execution_strategy_class = query.schema.mutation_execution_strategy
        end
        execution_strategy = execution_strategy_class.new
        query.context.execution_strategy = execution_strategy
        result = execution_strategy.execute(operation, root_type, query)
      end

      def find_operation(operation_name, operations)
        if operations.length == 1
          operations.values.first
        elsif !operations.key?(operation_name)
          raise OperationNameMissingError, operations.keys
        else
          operations[operation_name]
        end
      end
    end
  end
end
