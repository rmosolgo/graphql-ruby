# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  class RuntimeError < Error
    include GraphQL::Execution::Finalizer
  end
end
