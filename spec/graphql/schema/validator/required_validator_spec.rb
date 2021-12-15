# frozen_string_literal: true
require "spec_helper"
require_relative "./validator_helpers"

describe GraphQL::Schema::Validator::RequiredValidator do
  include ValidatorHelpers

  expectations = [
    {
      config: { one_of: [:a, :b] },
      cases: [
        { query: "{ validated: multiValidated(a: 1, b: 2) }", result: nil, error_messages: ["multiValidated has the wrong arguments"] },
        { query: "{ validated: multiValidated(a: 1, b: 2, c: 3) }", result: nil, error_messages: ["multiValidated has the wrong arguments"] },
        { query: "{ validated: multiValidated }", result: nil, error_messages: ["multiValidated has the wrong arguments"] },
        { query: "{ validated: multiValidated(c: 3) }", result: nil, error_messages: ["multiValidated has the wrong arguments"] },
        { query: "{ validated: multiValidated(a: 1) }", result: 1, error_messages: [] },
        { query: "{ validated: multiValidated(a: 1, c: 3) }", result: 4, error_messages: [] },
        { query: "{ validated: multiValidated(b: 2) }", result: 2, error_messages: [] },
        { query: "{ validated: multiValidated(b: 2, c: 3) }", result: 5, error_messages: [] },
      ]
    },
    {
      config: { one_of: [:a, [:b, :c]] },
      cases: [
        { query: "{ validated: multiValidated(a: 1) }", result: 1, error_messages: [] },
        { query: "{ validated: multiValidated(b: 2, c: 3) }", result: 5, error_messages: [] },
        { query: "{ validated: multiValidated }", result: nil, error_messages: ["multiValidated has the wrong arguments"] },
        { query: "{ validated: multiValidated(a: 1, b: 2, c: 3) }", result: nil, error_messages: ["multiValidated has the wrong arguments"] },
        { query: "{ validated: multiValidated(c: 3) }", result: nil, error_messages: ["multiValidated has the wrong arguments"] },
        { query: "{ validated: multiValidated(b: 2) }", result: nil, error_messages: ["multiValidated has the wrong arguments"] },
      ]
    },
    {
      name: "Input object validation",
      config: { one_of: [:a, [:b, :c]] },
      cases: [
        { query: "{ validated: validatedInput(input: { a: 1 }) }", result: 1, error_messages: [] },
        { query: "{ validated: validatedInput(input: { b: 2, c: 3 }) }", result: 5, error_messages: [] },
        { query: "{ validated: validatedInput(input: { a: 1, b: 2, c: 3 }) }", result: nil, error_messages: ["ValidatedInput has the wrong arguments"] },
        { query: "{ validated: validatedInput(input: { c: 3 }) }", result: nil, error_messages: ["ValidatedInput has the wrong arguments"] },
        { query: "{ validated: validatedInput(input: { b: 2 }) }", result: nil, error_messages: ["ValidatedInput has the wrong arguments"] },
      ]
    },
    {
      name: "Resolver validation",
      config: { one_of: [:a, [:b, :c]] },
      cases: [
        { query: "{ validated: validatedResolver(a: 1) }", result: 1, error_messages: [] },
        { query: "{ validated: validatedResolver(b: 2, c: 3) }", result: 5, error_messages: [] },
        { query: "{ validated: validatedResolver(a: 1, b: 2, c: 3) }", result: nil, error_messages: ["validatedResolver has the wrong arguments"] },
        { query: "{ validated: validatedResolver(c: 3) }", result: nil, error_messages: ["validatedResolver has the wrong arguments"] },
        { query: "{ validated: validatedResolver(b: 2) }", result: nil, error_messages: ["validatedResolver has the wrong arguments"] },
        { query: "{ validated: validatedResolver }", result: nil, error_messages: ["validatedResolver has the wrong arguments"] },
      ]
    },
    {
      name: "Single arg validation",
      config: { argument: :a, message: "A value must be given, even if it's `null`" },
      cases: [
        { query: "{ validated: validatedInput(input: { a: 1 }) }", result: 1, error_messages: [] },
        { query: "{ validated: validatedInput(input: {}) }", result: nil, error_messages: ["A value must be given, even if it's `null`"] },
        { query: "{ validated: validatedInput(input: { a: null }) }", result: 0, error_messages: [] },
      ]
    }
  ]

  build_tests(:required, Integer, expectations)
end
