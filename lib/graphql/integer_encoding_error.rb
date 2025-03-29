# frozen_string_literal: true
module GraphQL
  # This error is raised when `Types::Int` is asked to return a value outside of 32-bit integer range.
  #
  # For values outside that range, consider:
  #
  # - `ID` for database primary keys or other identifiers
  # - `GraphQL::Types::BigInt` for really big integer values
  #
  # @see GraphQL::Types::Int which raises this error
  class IntegerEncodingError < GraphQL::ScalarCoercionError
  end
end
