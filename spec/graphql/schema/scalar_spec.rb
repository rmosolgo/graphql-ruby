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
  end
end
