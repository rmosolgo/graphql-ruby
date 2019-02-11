# frozen_string_literal: true
module GraphQL
  class IntegerEncodingError < GraphQL::RuntimeTypeError
    def initialize
      super('Integer out of bounds.')
    end
  end
end
