# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # Wrapper for raw values
      class RawValue
        include GraphQL::Execution::Next::Finalizer

        def finalize_graphql_result(query, result_data, result_key)
          result_data[result_key] = @object
        end

        def initialize(obj = nil)
          @object = obj
        end

        def resolve
          @object
        end
      end
    end
  end
end
