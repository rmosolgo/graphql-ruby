# frozen_string_literal: true
require "spec_helper"
require_relative "./validator_helpers"

describe GraphQL::Schema::Validator::AllowNullValidator do
  include ValidatorHelpers

  it "allows nil when permitted" do
    build_schema(String, {length: { minimum: 5 }, allow_null: true})
    result = exec_query("query($str: String) { validated(value: $str) }", variables: { str: nil })
    assert_nil result["data"]["validated"]
    refute result.key?("errors")
  end

  it "rejects null by default" do
    build_schema(String, {length: { minimum: 5 }})
    result = exec_query("query($str: String) { validated(value: $str) }", variables: { str: nil })
    assert_nil result["data"]["validated"]
    assert_equal ["value is too short (minimum is 5)"], result["errors"].map { |e| e["message"] }
  end

  it "can be used standalone" do
    build_schema(String, { allow_null: false })
    result = exec_query("query($str: String) { validated(value: $str) }", variables: { str: nil })
    assert_nil result["data"]["validated"]
    assert_equal ["value can't be null"], result["errors"].map { |e| e["message"] }
  end

  it "allows nil when no validations are configured" do
    build_schema(String, {})
    result = exec_query("query($str: String) { validated(value: $str) }", variables: { str: nil })
    assert_nil result["data"]["validated"]
    refute result.key?("errors")

    result = exec_query("query { validated }")
    assert_nil result["data"]["validated"]
    refute result.key?("errors")
  end
end
