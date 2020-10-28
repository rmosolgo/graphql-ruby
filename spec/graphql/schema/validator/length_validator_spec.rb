# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Validator::LengthValidator do
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

  it "allows blank and null" do
    schema = build_schema(String, {length: { minimum: 5, allow_blank: true}})

    blank_string = BlankString.new("")
    assert blank_string.blank?
    result = schema.execute("query($str: String!) { validated(value: $str) }", variables: { str: blank_string })
    assert_equal "", result["data"]["validated"]
    refute result.key?("errors")

    result = schema.execute("query($str: String!) { validated(value: $str) }", variables: { str: nil })
    refute result.key?("data")
    assert_equal ["Variable $str of type String! was provided invalid value"],  result["errors"].map { |e| e["message"] }

    schema = build_schema(String, {length: { minimum: 5, allow_null: true}})
    result = schema.execute("{ validated(value: null) }")
    assert_equal nil, result["data"]["validated"]
    refute result.key?("errors")

    result = schema.execute("query($str: String!) { validated(value: $str) }", variables: { str: blank_string })
    assert_nil result["data"].fetch("validated")
    assert_equal ["value can't be blank"], result["errors"].map { |e| e["message"] }

    # This string doesn't respond to blank:
    non_blank_string = NonBlankString.new("")
    result = schema.execute("query($str: String!) { validated(value: $str) }", variables: { str: non_blank_string })
    assert_nil result["data"].fetch("validated")
    assert_equal ["value is too short (minimum is 5)"], result["errors"].map { |e| e["message"] }
  end

  it "validates minimum length" do
    schema = build_schema(String, {length: { minimum: 5 }})
    result = schema.execute("{ validated(value: \"is-valid\") }")
    assert_equal "is-valid", result["data"]["validated"]
    refute result.key?("errors")

    result = schema.execute("{ validated(value: \"nono\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["value is too short (minimum is 5)"], result["errors"].map { |e| e["message"] }
  end

  it "validates maximum length" do
    schema = build_schema(String, {length: { maximum: 8 }})
    result = schema.execute("{ validated(value: \"is-valid\") }")
    assert_equal "is-valid", result["data"]["validated"]
    refute result.key?("errors")

    result = schema.execute("{ validated(value: \"is-invalid\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["value is too long (maximum is 8)"], result["errors"].map { |e| e["message"] }
  end

  it "validates within length" do
    schema = build_schema(String, {length: { within: 5..8 }})
    result = schema.execute("{ validated(value: \"is-valid\") }")
    assert_equal "is-valid", result["data"]["validated"]
    refute result.key?("errors")

    result = schema.execute("{ validated(value: \"nono\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["value is too short (minimum is 5)"], result["errors"].map { |e| e["message"] }

    result = schema.execute("{ validated(value: \"is-invalid\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["value is too long (maximum is 8)"], result["errors"].map { |e| e["message"] }
  end

  it "validates length is" do
    schema = build_schema(String, {length: { is: 8 }})
    result = schema.execute("{ validated(value: \"is-valid\") }")
    assert_equal "is-valid", result["data"]["validated"]
    refute result.key?("errors")

    result = schema.execute("{ validated(value: \"nono\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["value is the wrong length (should be 8)"], result["errors"].map { |e| e["message"] }

    result = schema.execute("{ validated(value: \"is-invalid\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["value is the wrong length (should be 8)"], result["errors"].map { |e| e["message"] }
  end

  it "applies custom messages" do
    schema = build_schema(String, {length: { is: 8, wrong_length: "Instead, make %{argument} have length %{count}" }})
    result = schema.execute("{ validated(value: \"is-invalid\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["Instead, make value have length 8"], result["errors"].map { |e| e["message"] }

    schema = build_schema(String, {length: { minimum: 50, too_short: "Instead, make %{argument} have length at least %{count}" }})
    result = schema.execute("{ validated(value: \"is-invalid\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["Instead, make value have length at least 50"], result["errors"].map { |e| e["message"] }

    schema = build_schema(String, {length: { maximum: 5, too_long: "Instead, make %{argument} have length less than %{count}" }})
    result = schema.execute("{ validated(value: \"is-invalid\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["Instead, make value have length less than 5"], result["errors"].map { |e| e["message"] }

    schema = build_schema(String, {length: { minimum: 50, message: "NO, BAD! %{argument} %{count}" }})
    result = schema.execute("{ validated(value: \"is-invalid\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["NO, BAD! value 50"], result["errors"].map { |e| e["message"] }
  end
end
