# frozen_string_literal: true
require "spec_helper"
require_relative "./validator_helpers"

describe GraphQL::Schema::Validator::RequiredValidator do
  include ValidatorHelpers

  # When rails is loaded, the blank validator kicks in:
  if {}.respond_to?(:blank?)
    no_args_message = "multiValidated can't be blank"
    resolver_no_args_message = "validatedResolver can't be blank"
  else
    no_args_message = "multiValidated has the wrong arguments"
    resolver_no_args_message = "validatedResolver has the wrong arguments"
  end

  expectations = [
    {
      config: { one_of: [:a, :b] },
      cases: [
        { query: "{ validated: multiValidated(a: 1, b: 2) }", result: nil, error_messages: ["multiValidated has the wrong arguments"] },
        { query: "{ validated: multiValidated(a: 1, b: 2, c: 3) }", result: nil, error_messages: ["multiValidated has the wrong arguments"] },
        { query: "{ validated: multiValidated }", result: nil, error_messages: [no_args_message] },
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
        { query: "{ validated: multiValidated }", result: nil, error_messages: [no_args_message] },
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
        { query: "{ validated: validatedResolver }", result: nil, error_messages: [resolver_no_args_message] },
      ]
    }
  ]

  build_tests(:required, Integer, expectations)
end
