# frozen_string_literal: true
#--
# typed: strict

module GraphQL
  module Execution
    class Interpreter
      # Wrapper for raw values
      class RawValue
        include GraphQL::Execution::Finalizer

        #: (GraphQL::Query query, untyped result_data, String | Integer result_key) -> void
        def finalize_graphql_result(query, result_data, result_key)
          result_data[result_key] = @object
        end

        #: (?untyped obj) -> void
        def initialize(obj = nil)
          @object = obj #: untyped
        end

        #: -> untyped
        def resolve
          @object
        end
      end
    end
  end
end
