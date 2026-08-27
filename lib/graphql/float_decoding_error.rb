# frozen_string_literal: true
module GraphQL
  # This error is raised when `Types::Float` is given a non-finite input value.
  class FloatDecodingError < GraphQL::RuntimeTypeError
    # The value which couldn't be decoded
    attr_reader :float_value

    def initialize(value)
      @float_value = value
      super("Float is not finite: #{value.inspect}.")
    end
  end
end
