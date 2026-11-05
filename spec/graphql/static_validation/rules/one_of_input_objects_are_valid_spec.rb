# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::OneOfInputObjectsAreValid do
  include StaticValidationHelpers

  let(:schema) {
    GraphQL::Schema.from_definition(%|
      type Query {
        oneOfArgField(oneOfArg: OneOfArgInput): String
      }

      input OneOfArgInput @oneOf {
        stringField: String
        intField: Int
      }
    |)
  }

  describe "with exactly one field" do
    let(:query_string) {%|
      {
        oneOfArgField(oneOfArg: { stringField: "abc" })
      }
    |}

    it "finds no errors" do
      assert_equal [], errors
    end
  end

  describe "with exactly one non-nullable variable" do
    let(:query_string) {%|
      query ($string: String!) {
        oneOfArgField(oneOfArg: { stringField: $string })
      }
    |}

    it "finds no errors" do
      assert_equal [], errors
    end
  end

  describe "with an invalid field type" do
    let(:query_string) {%|
      {
        oneOfArgField(oneOfArg: { stringField: 2 })
      }
    |}

    it "finds errors" do
      expected = [
        {
          "message" => "Argument 'stringField' on InputObject 'OneOfArgInput' has an invalid value (2). " \
                       "Expected type 'String'.",
          "locations" => [{ "line" => 3, "column" => 33 }],
          "path" => ["query", "oneOfArgField", "oneOfArg", "stringField"],
          "extensions" => {
            "code" => "argumentLiteralsIncompatible",
            "typeName" => "InputObject",
            "argumentName" => "stringField"
          }
        }
      ]

      assert_equal expected, errors
    end
  end

  describe "with exactly one null field" do
    let(:query_string) {%|
      {
        oneOfArgField(oneOfArg: { stringField: null })
      }
    |}

    it "finds errors" do
      expected = [
        {
          "message" => "Argument 'OneOfArgInput.stringField' must be non-null.",
          "locations" => [{ "line" => 3, "column" => 35 }],
          "path" => ["query", "oneOfArgField", "oneOfArg", "stringField"],
          "extensions" => {
            "code" => "invalidOneOfInputObject",
            "inputObjectType" => "OneOfArgInput"
          }
        }
      ]

      assert_equal expected, errors
    end
  end

  describe "with exactly one nullable variable" do
    let(:query_string) {%|
      query ($string: String) {
        oneOfArgField(oneOfArg: { stringField: $string })
      }
    |}

    it "finds errors" do
      expected = [
        {
          "message" => "Variable 'string' must be non-nullable to be used for OneOf Input Object 'OneOfArgInput'.",
          "locations"=>[{ "line" => 3, "column" => 33 }],
          "path" => ["query", "oneOfArgField", "oneOfArg", "stringField"],
          "extensions" => {
            "code" => "invalidOneOfInputObject",
            "inputObjectType" => "OneOfArgInput"
          }
        }
      ]

      assert_equal expected, errors
    end
  end

  describe "with an undeclared variable" do
    let(:query_string) {%|
      {
        oneOfArgField(oneOfArg: { stringField: $undeclared })
      }
    |}

    it "only reports the undeclared variable" do
      assert_equal ["Variable $undeclared is used by anonymous query but not declared"], errors.map { |e| e["message"] }
    end

    it "doesn't raise when run without the variable rules" do
      # This rule depends on helpers from other rules, so it can't run completely alone
      rules = GraphQL::StaticValidation::ALL_RULES - [
        GraphQL::StaticValidation::VariableUsagesAreAllowed,
        GraphQL::StaticValidation::VariablesAreUsedAndDefined,
      ]
      validator = GraphQL::StaticValidation::Validator.new(schema: schema, rules: rules)
      query = GraphQL::Query.new(schema, query_string)
      assert_equal [], validator.validate(query)[:errors]
    end
  end

  describe "with more than one field" do
    let(:query_string) {%|
      {
        oneOfArgField(oneOfArg: { stringField: "abc", intField: 2 })
      }
    |}

    it "finds errors" do
      expected = [
        {
          "message" => "OneOf Input Object 'OneOfArgInput' must specify exactly one key.",
          "locations" => [{ "line" => 3, "column" => 33 }],
          "path" => ["query", "oneOfArgField", "oneOfArg"],
          "extensions" => {
            "code" => "invalidOneOfInputObject",
            "inputObjectType" => "OneOfArgInput"
          }
        }
      ]

      assert_equal expected, errors
    end
  end
end
