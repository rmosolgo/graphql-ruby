# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Scalar do
  describe "in queries" do
    it "becomes output" do
      query_str = <<-GRAPHQL
      {
        find(id: "Musician/Herbie Hancock") {
          ... on Musician {
            name
            favoriteKey
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      assert_equal "B♭", res["data"]["find"]["favoriteKey"]
    end

    it "can be input" do
      query_str = <<-GRAPHQL
      {
        inspectKey(key: "F♯") {
          root
          isSharp
          isFlat
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      key_info = res["data"]["inspectKey"]
      assert_equal "F", key_info["root"]
      assert_equal true, key_info["isSharp"]
      assert_equal false, key_info["isFlat"]
    end

    it "can be nested JSON" do
      query_str = <<-GRAPHQL
      {
        echoJson(input: {foo: [{bar: "baz"}]})
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      assert_equal({"foo" => [{"bar" => "baz"}]}, res["data"]["echoJson"])
    end

    it "can be a JSON array" do
      query_str = <<-GRAPHQL
      {
        echoFirstJson(input: [{foo: "bar"}, {baz: "boo"}])
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      assert_equal({"foo" => "bar"}, res["data"]["echoFirstJson"])
    end

    it "can be a JSON array even if the GraphQL type is not an array" do
      query_str = <<-GRAPHQL
      {
        echoJson(input: [{foo: "bar"}])
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      assert_equal([{"foo" => "bar"}], res["data"]["echoJson"])
    end

    it "can be JSON with a nested enum" do
      query_str = <<-GRAPHQL
      {
        echoJson(input: [{foo: WOODWIND}])
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      assert_equal([{"foo" => "WOODWIND"}], res["data"]["echoJson"])
    end

    it "cannot be JSON with a nested variable" do
      query_str = <<-GRAPHQL
      {
        echoJson(input: [{foo: $var}])
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      assert_includes(res["errors"][0]["message"], "Argument 'input' on Field 'echoJson' has an invalid value")
    end
  end
end
