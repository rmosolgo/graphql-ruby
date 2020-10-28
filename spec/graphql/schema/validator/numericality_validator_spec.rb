# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Validator::NumericalityValidator do
  def build_schema(arg_type, validates_config)
    schema = Class.new(GraphQL::Schema)
    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"
      field :validated, arg_type, null: true do
        argument :value, arg_type, required: false, validates: validates_config
      end

      def validated(value:)
        value
      end
    end
    schema.query(query_type)
    schema
  end

  expectations = [
    {
      config: { less_than: 10, greater_than: 2, allow_null: true },
      cases: [
        { query: "{ validated(value: 8) }", result: 8, error_messages: [] },
        { query: "{ validated(value: 12) }", result: nil, error_messages: ["value must be less than 10"] },
        { query: "{ validated(value: 1) }", result: nil, error_messages: ["value must be greater than 2"] },
        { query: "{ validated(value: null) }", result: nil, error_messages: [] },
      ]
    },
    {
      config: { less_than_or_equal_to: 10, greater_than_or_equal_to: 2 },
      cases: [
        { query: "{ validated(value: 8) }", result: 8, error_messages: [] },
        { query: "{ validated(value: 10) }", result: 10, error_messages: [] },
        { query: "{ validated(value: 2) }", result: 2, error_messages: [] },
        { query: "{ validated(value: 12) }", result: nil, error_messages: ["value must be less than or equal to 10"] },
        { query: "{ validated(value: 1) }", result: nil, error_messages: ["value must be greater than or equal to 2"] },
      ]
    },
    {
      config: { odd: true },
      cases: [
        { query: "{ validated(value: 9) }", result: 9, error_messages: [] },
        { query: "{ validated(value: 8) }", result: nil, error_messages: ["value must be odd"] },
      ]
    },
    {
      config: { even: true },
      cases: [
        { query: "{ validated(value: 8) }", result: 8, error_messages: [] },
        { query: "{ validated(value: 9) }", result: nil, error_messages: ["value must be even"] },
      ]
    },
    {
      config: { equal_to: 8 },
      cases: [
        { query: "{ validated(value: 8) }", result: 8, error_messages: [] },
        { query: "{ validated(value: 9) }", result: nil, error_messages: ["value must be equal to 8"] },
      ]
    },
    {
      config: { other_than: 9 },
      cases: [
        { query: "{ validated(value: 8) }", result: 8, error_messages: [] },
        { query: "{ validated(value: 9) }", result: nil, error_messages: ["value must be something other than 9"] },
      ]
    },
  ]

  expectations.each do |expectation|
    it "works with #{expectation[:config]}" do
      schema = build_schema(Integer, { numericality: expectation[:config] })
      expectation[:cases].each do |test_case|
        result = schema.execute(test_case[:query])
        if test_case[:result].nil?
          assert_nil result["data"]["validated"]
        else
          assert_equal test_case[:result], result["data"]["validated"]
        end
        assert_equal test_case[:error_messages], (result["errors"] || []).map { |e| e["message"] }
      end
    end
  end

  it "applies custom messages" do
    skip
  end
end
