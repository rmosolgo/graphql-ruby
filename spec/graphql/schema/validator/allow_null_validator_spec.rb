# frozen_string_literal: true
require "spec_helper"
require_relative "./validator_helpers"

describe GraphQL::Schema::Validator::AllowNullValidator do
  include ValidatorHelpers

  class BlankString < String
    def blank?
      true
    end
  end

  class NonBlankString < String
    if method_defined?(:blank?)
      undef :blank?
    end
  end

  it "allows nil by default" do
    schema = build_schema(String, {length: { minimum: 5 }})
    result = schema.execute("query($str: String) { validated(value: $str) }", variables: { str: nil })
    assert_equal nil, result["data"]["validated"]
    refute result.key?("errors")
  end

  it "rejects null when not permitted" do
    schema = build_schema(String, {length: { minimum: 5 }, allow_null: false})
    result = schema.execute("query($str: String) { validated(value: $str) }", variables: { str: nil })
    assert_equal nil, result["data"]["validated"]
    assert_equal ["value can't be null"], result["errors"].map { |e| e["message"] }
  end
end
