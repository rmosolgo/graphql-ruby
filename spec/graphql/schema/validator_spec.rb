# frozen_string_literal: true
require "spec_helper"
require_relative "./validator/validator_helpers"

describe GraphQL::Schema::Validator do
  include ValidatorHelpers

  class CustomValidator < GraphQL::Schema::Validator
    def initialize(equal_to:, **rest)
      @equal_to = equal_to
      super(**rest)
    end

    def validate(object, context, value)
      if value == @equal_to
        nil
      else
        "%{validated} doesn't have the right the right value"
      end
    end
  end

  before do
    GraphQL::Schema::Validator.install(:custom, CustomValidator)
  end

  after do
    GraphQL::Schema::Validator.uninstall(:custom)
  end

  build_tests(CustomValidator, Integer, [
    {
      name: "with a validator class as name",
      config: { equal_to: 2 },
      cases: [
        { query: "{ validated(value: 2) }", error_messages: [], result: 2 },
        { query: "{ validated(value: 3) }", error_messages: ["Query.validated.value doesn't have the right the right value"], result: nil },
      ]
    }
  ])

  build_tests(:custom, Integer, [
    {
      name: "with an installed symbol name",
      config: { equal_to: 4 },
      cases: [
        { query: "{ validated(value: 4) }", error_messages: [], result: 4 },
        { query: "{ validated(value: 3) }", error_messages: ["Query.validated.value doesn't have the right the right value"], result: nil },
      ]
    }
  ])
end