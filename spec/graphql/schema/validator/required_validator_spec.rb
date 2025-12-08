# frozen_string_literal: true
require "spec_helper"
require_relative "./validator_helpers"

describe GraphQL::Schema::Validator::RequiredValidator do
  include ValidatorHelpers

  expectations = [
    {
      config: { one_of: [:a, :b, :secret] },
      cases: [
        { query: "{ validated: multiValidated(a: 1, b: 2) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, b."] },
        { query: "{ validated: multiValidated(a: 1, b: 2, c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, b."] },
        { query: "{ validated: multiValidated }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, b."] },
        { query: "{ validated: multiValidated(c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, b."] },
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
        { query: "{ validated: multiValidated }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: multiValidated(a: 1, b: 2, c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: multiValidated(a: 1, b: 2) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: multiValidated(a: 1, c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: multiValidated(c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: multiValidated(b: 2) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, (b and c)."] },
      ]
    },
    {
      name: "All options hidden, allow_all_hidden: true",
      config: { one_of: [:secret, :secret2], allow_all_hidden: true },
      cases: [
        { query: "{ validated: multiValidated(a: 1, b: 2) }", result: 3, error_messages: [] },
      ],
    },
    {
      name: "Definition order independence",
      config: { one_of: [[:a, :b], :c] },
      cases: [
        { query: "{ validated: multiValidated(c: 1) }", result: 1, error_messages: [] },
        { query: "{ validated: multiValidated(a: 2, b: 3) }", result: 5, error_messages: [] },
        { query: "{ validated: multiValidated }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: (a and b), c."] },
        { query: "{ validated: multiValidated(a: 1, b: 2, c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: (a and b), c."] },
        { query: "{ validated: multiValidated(a: 1, c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: (a and b), c."] },
        { query: "{ validated: multiValidated(b: 2, c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: (a and b), c."] },
        { query: "{ validated: multiValidated(a: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: (a and b), c."] },
        { query: "{ validated: multiValidated(b: 2) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: (a and b), c."] },
      ]
    },
    {
      name: "Input object validation",
      config: { one_of: [:a, [:b, :c]] },
      cases: [
        { query: "{ validated: validatedInput(input: { a: 1 }) }", result: 1, error_messages: [] },
        { query: "{ validated: validatedInput(input: { b: 2, c: 3 }) }", result: 5, error_messages: [] },
        { query: "{ validated: validatedInput(input: { a: 1, b: 2, c: 3 }) }", result: nil, error_messages: ["ValidatedInput must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedInput(input: { a: 1, b: 2 }) }", result: nil, error_messages: ["ValidatedInput must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedInput(input: { a: 1, c: 3 }) }", result: nil, error_messages: ["ValidatedInput must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedInput(input: { c: 3 }) }", result: nil, error_messages: ["ValidatedInput must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedInput(input: { b: 2 }) }", result: nil, error_messages: ["ValidatedInput must include exactly one of the following arguments: a, (b and c)."] },
      ]
    },
    {
      name: "Resolver validation",
      config: { one_of: [:a, [:b, :c]] },
      cases: [
        { query: "{ validated: validatedResolver(a: 1) }", result: 1, error_messages: [] },
        { query: "{ validated: validatedResolver(b: 2, c: 3) }", result: 5, error_messages: [] },
        { query: "{ validated: validatedResolver(a: 1, b: 2, c: 3) }", result: nil, error_messages: ["validatedResolver must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedResolver(a: 1, b: 2) }", result: nil, error_messages: ["validatedResolver must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedResolver(a: 1, c: 3) }", result: nil, error_messages: ["validatedResolver must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedResolver(c: 3) }", result: nil, error_messages: ["validatedResolver must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedResolver(b: 2) }", result: nil, error_messages: ["validatedResolver must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedResolver }", result: nil, error_messages: ["validatedResolver must include exactly one of the following arguments: a, (b and c)."] },
      ]
    },
    {
      name: "Single arg validation",
      config: { argument: :a, message: "A value must be given, even if it's `null` (not %{value})" },
      cases: [
        { query: "{ validated: validatedInput(input: { a: 1 }) }", result: 1, error_messages: [] },
        { query: "{ validated: validatedInput(input: {}) }", result: nil, error_messages: ["A value must be given, even if it's `null` (not {})"] },
        { query: "{ validated: validatedInput(input: { a: null }) }", result: 0, error_messages: [] },
      ]
    }
  ]

  build_tests(:required, Integer, expectations)


  describe "when all arguments are hidden" do
    class RequiredHiddenSchema < GraphQL::Schema
      class BaseArgument < GraphQL::Schema::Argument
        def initialize(*args, always_hidden: false, **kwargs, &block)
          super(*args, **kwargs, &block)
          @always_hidden = always_hidden
        end

        def visible?(ctx)
          !@always_hidden
        end
      end

      class BaseField < GraphQL::Schema::Field
        argument_class(BaseArgument)
      end

      class Query < GraphQL::Schema::Object
        field_class(BaseField)

        field :one_argument, Int, fallback_value: 1 do
          argument :a, Int, required: :nullable, always_hidden: true
        end

        field :two_arguments, Int, fallback_value: 2 do
          validates required: { one_of: [:a, :b], allow_all_hidden: true }
          argument :a, Int, required: false, always_hidden: true
          argument :b, Int, required: false, always_hidden: true
        end

        field :two_arguments_error, Int, fallback_value: 2 do
          validates required: { one_of: [:a, :b] }
          argument :a, Int, required: false, always_hidden: true
          argument :b, Int, required: false, always_hidden: true
        end

        field :three_arguments, Int, fallback_value: 3 do
          validates required: { one_of: [:a, :b], allow_all_hidden: true }
          argument :a, Int, required: false, always_hidden: true
          argument :b, Int, required: false, always_hidden: true
          argument :c, Int
        end

        field :four_arguments, Int, fallback_value: 4 do
          validates required: { one_of: [[:a, :b], :c, :d], allow_all_hidden: true}
          argument :a, Int, required: false, always_hidden: true
          argument :b, Int, required: false, always_hidden: true
          argument :c, Int, required: false, always_hidden: true
          argument :d, Int, required: false, always_hidden: true
        end
      end

      query(Query)
      use GraphQL::Schema::Visibility
    end

    it "Doesn't require any of one_of to be present" do
      result = RequiredHiddenSchema.execute("{ threeArguments(c: 5) }")
      assert_equal 3, result["data"]["threeArguments"]

      result = RequiredHiddenSchema.execute("{ twoArguments }")
      assert_equal 2, result["data"]["twoArguments"]

      err = assert_raises GraphQL::Error do
        RequiredHiddenSchema.execute("{ twoArgumentsError }")
      end

      expected_message = "Query.twoArgumentsError validates `required: ...` but all required arguments were hidden.\n\nUpdate your schema definition to allow the client to see some fields or skip validation by adding `required: { ..., allow_all_hidden: true }`\n"
      assert_equal expected_message, err.message
    end

    it "doesn't require hidden arguments when required as a group" do
      result = RequiredHiddenSchema.execute("{ fourArguments }")
      assert_equal 4, result["data"]["fourArguments"]
    end

    it "Doesn't require hidden argument to be present" do
      result = RequiredHiddenSchema.execute("{ oneArgument }")
      assert_equal 1, result["data"]["oneArgument"]
    end
  end
end
