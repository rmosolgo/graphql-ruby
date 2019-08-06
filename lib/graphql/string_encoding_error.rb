# frozen_string_literal: true
module GraphQL
  class StringEncodingError < GraphQL::RuntimeTypeError
    attr_reader :string
    def initialize(str)
      @string = str
      super("String \"#{str}\" was encoded as #{str.encoding}! GraphQL requires an encoding compatible with UTF-8.")
    end
  end
end
