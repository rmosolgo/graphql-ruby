# frozen_string_literal: true

module GraphQL
  # This can be raised inside a {GraphQL::Schema::FancyMutation},
  # if it is, it's rendered into `userErrors`.
  class UserError < GraphQL::Error
    # @return [Array<String>]
    attr_accessor :fields
    def initialize(message, fields: nil)
      @fields = fields
      super(message)
    end
  end
end
