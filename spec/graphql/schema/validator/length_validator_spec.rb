# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Validator::LengthValidator do
  def build_schema(arg_type, validates_config)
    schema = Class.new(GraphQL::Schema)
    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"
      field :validated, arg_type, null: true do
        argument :value, arg_type, required: true, validates: validates_config
      end

      def validated(value:)
        value
      end
    end
    schema.query(query_type)
    schema
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
