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
  class IntegerEncodingError < GraphQL::RuntimeTypeError
    # The value which couldn't be encoded
    attr_reader :integer_value

    def initialize(value)
      @integer_value = value
      super("Integer out of bounds: #{value}. \nConsider using ID or GraphQL::Types::BigInt instead.")
    end
  end
end
