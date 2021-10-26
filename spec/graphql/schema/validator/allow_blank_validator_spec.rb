# frozen_string_literal: true
require "spec_helper"
require_relative "./validator_helpers"

describe GraphQL::Schema::Validator::AllowBlankValidator do
  include ValidatorHelpers

  it "allows blank when configured" do
    schema = build_schema(String, {length: { minimum: 5 }, allow_blank: true})
    result = schema.execute("query($str: String) { validated(value: $str) }", variables: { str: ValidatorHelpers::BlankString.new })
    assert_equal "", result["data"]["validated"]
    refute result.key?("errors")
  end

  it "rejects blank by default" do
    schema = build_schema(String, {length: { minimum: 5 }})
    result = schema.execute("query($str: String) { validated(value: $str) }", variables: { str: ValidatorHelpers::BlankString.new })
    assert_equal nil, result["data"]["validated"]
    assert_equal ["value is too short (minimum is 5)"], result["errors"].map { |e| e["message"] }
  end

  it "can be used standalone" do
    schema = build_schema(String, { allow_blank: false })
    result = schema.execute("query($str: String) { validated(value: $str) }", variables: { str: ValidatorHelpers::BlankString.new })
    assert_equal nil, result["data"]["validated"]
    assert_equal ["value can't be blank"], result["errors"].map { |e| e["message"] }
  end
end
