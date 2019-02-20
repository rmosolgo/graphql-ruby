# frozen_string_literal: true
module GraphQL
  class IntegerEncodingError < GraphQL::RuntimeTypeError
    # The value which couldn't be encoded
    attr_reader :integer_value

    def initialize(value)
      @integer_value = value
      super('Integer out of bounds.')
    end
  end
end
