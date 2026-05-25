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
    allow_null = false
    msg = "can't be Null!!"
    build_schema(String, { allow_null: { allow_null: -> { allow_null }, message: -> { msg } } })
    result = exec_query("query($str: String) { validated(value: $str) }", variables: { str: nil })
    assert_nil result["data"]["validated"]
    assert_equal ["can't be Null!!"], result["errors"].map { |e| e["message"] }

    allow_null = true
    result = exec_query("query($str: String) { validated(value: $str) }", variables: { str: nil })
    refute result.key?("errors")
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
