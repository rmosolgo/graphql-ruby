module GraphQL
  class Query
    # An execution of a query with a specific context, variables, and operation name.
    #
    # This is an implementation detail of {QueryCache#execute}, allowing it to
    # execute a {GraphQL::Query} more than once.
    class Run
      extend Forwardable

      def initialize(query, context:, variables:, operation_name:)
        @query = query
        @operation_name = operation_name
        @provided_context = context
        @provided_variables = variables
      end


      # Determine the values for variables of this query, using default values
      # if a value isn't provided at runtime.
      #
      # Raises if a non-null variable isn't provided at runtime.
      # @return [GraphQL::Query::Variables] Variables to apply to this query
      def variables
        @variables ||= GraphQL::Query::Variables.new(
          @query.schema,
          @selected_operation.variables,
          @provided_variables
        )
      end

      def context
        @context ||= Context.new(query: self, values: @provided_context)
      end

      # This is the operation to run for this query.
      # If more than one operation is present, it must be named at runtime.
      # @return [GraphQL::Language::Nodes::OperationDefinition, nil]
      def selected_operation
        @selected_operation ||= find_operation(@query.operations, @operation_name)
      end

      def_delegators :@query, :operations, :fragments, :schema, :debug, :max_depth

      private

      def find_operation(operations, operation_name)
        if operations.length == 1
          operations.values.first
        elsif operations.length == 0
          nil
        elsif !operations.key?(operation_name)
          raise OperationNameMissingError, operations.keys
        else
          operations[operation_name]
        end
      end
    end
  end
end
