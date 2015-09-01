module GraphQL
  class Query
    class Executor
      class OperationNameMissingError < StandardError
        def initialize(names)
          msg = "You must provide an operation name from: #{names.join(", ")}"
          super(msg)
        end
      end

      attr_reader :query, :operation_name
      def initialize(query, operation_name)
        @query = query
        @operation_name = operation_name
      end

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
          execution_strategy_class = query.schema.query_execution_strategy || GraphQL::Query::ParallelExecution
        elsif operation.operation_type == "mutation"
          root_type = query.schema.mutation
          execution_strategy_class =  query.schema.mutation_execution_strategy || GraphQL::Query::SerialExecution
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
