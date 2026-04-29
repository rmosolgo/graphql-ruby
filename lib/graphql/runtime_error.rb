# frozen_string_literal: true
module GraphQL
  class RuntimeError < Error
    include GraphQL::Execution::Finalizer
  end
end
