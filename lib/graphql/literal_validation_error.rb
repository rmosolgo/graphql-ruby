# frozen_string_literal: true
module GraphQL
  class LiteralValidationError < GraphQL::Error
    attr_accessor :ast_value
  end
end
