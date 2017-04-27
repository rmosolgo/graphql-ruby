# frozen_string_literal: true
module GraphQL
  module Execution
    # @see {Schema#multiplex}
    # @api private
    class Multiplex
      NO_OPERATION = {}.freeze

      def self.run_all(queries)
        schema = queries.first.schema
        query_instrumenters = schema.instrumenters[:query]

        # TODO: this makes a lot of passes over the list of queries, can we reduce it?
        queries.each do |query|
          query_instrumenters.each { |i| i.before_query(query) }
        end

        results = queries.map do |query|
          operation = query.selected_operation
          if operation.nil? || !query.valid?
            NO_OPERATION
          else
            begin
              op_type = operation.operation_type
              root_type = query.root_type_for_operation(op_type)
              GraphQL::Execution::Execute::ExecutionFunctions.resolve_selection(
                query.root_value,
                root_type,
                query.irep_selection,
                query.context,
                mutation: query.mutation?
              )
            rescue GraphQL::ExecutionError => err
              query.context.errors << err
              {}
            end
          end
        end

        GraphQL::Execution::Lazy.resolve(results)

        results.each_with_index.map do |data_result, idx|
          query = queries[idx]
          # Assign the result so that it can be accessed in instrumentation
          query.result = if data_result.equal?(NO_OPERATION)
            if !query.valid?
              { "errors" => query.static_errors.map(&:to_h) }
            else
              {}
            end
          else
            result = { "data" => data_result.to_h }
            error_result = query.context.errors.map(&:to_h)

            if error_result.any?
              result["errors"] = error_result
            end

            result
          end
        end
      ensure
        queries.each do |query|
          query_instrumenters.each { |i| i.after_query(query) }
        end
      end
    end
  end
end
