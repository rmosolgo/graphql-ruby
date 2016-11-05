require "graphql/query/serial_execution/execution_context"
require "graphql/query/serial_execution/value_resolution"
require "graphql/query/serial_execution/field_resolution"
require "graphql/query/serial_execution/operation_resolution"
require "graphql/query/serial_execution/selection_resolution"

module GraphQL
  class Query
    class SerialExecution
      # This is the only required method for an Execution strategy.
      # You could create a custom execution strategy and configure your schema to
      # use that custom strategy instead.
      #
      # @param ast_operation [GraphQL::Language::Nodes::OperationDefinition] The operation definition to run
      # @param root_type [GraphQL::ObjectType] either the query type or the mutation type
      # @param query_obj [GraphQL::Query] the query object for this execution
      # @return [Hash] a spec-compliant GraphQL result, as a hash
      def execute(ast_operation, root_type, query)
        irep_root = query.internal_representation[ast_operation.name]

        frame = GraphQL::Execution::Frame.new(query: query, irep_node: irep_root, type: root_type)
        execution_context = ExecutionContext.new(query, self)
        result = operation_resolution.resolve(
          frame,
          root_type,
          execution_context
        )

        while query.accumulator.any?
          query.accumulator.resolve_all do |frame, value|
            case value
            when GraphQL::ExecutionError
              frame.add_error(value)
              value = nil
            end
            path = frame.path
            last = path.pop
            target = result
            path.each { |key| target = target[key] }
            finished_value = value_resolution.resolve(
              frame.type,
              frame.field,
              frame.field.type,
              value,
              frame,
              execution_context
            )
            target[last] = finished_value
          end
        end

        result
      end

      def field_resolution
        self.class::FieldResolution
      end

      def operation_resolution
        self.class::OperationResolution
      end

      def selection_resolution
        self.class::SelectionResolution
      end

      def value_resolution
        self.class::ValueResolution
      end
    end
  end
end
