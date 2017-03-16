# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Relay::ConnectionResolve do
  describe "when an execution error is returned" do
    let(:query_string) { <<-GRAPHQL
      query getError($error: String!){
        rebels {
          ships(nameIncludes: $error) {
            edges {
              node {
                name
              }
            }
          }
        }
      }
    GRAPHQL
    }

    it "adds an error" do
      result = star_wars_query(query_string, { "error" => "error"})
      assert_equal 1, result["errors"].length
      assert_equal "error from within connection", result["errors"][0]["message"]
    end

    it "adds an error for a lazy error" do
      result = star_wars_query(query_string, { "error" => "lazyError"})
      assert_equal 1, result["errors"].length
      assert_equal "lazy error from within connection", result["errors"][0]["message"]
    end

    it "adds an error for a lazy raised error" do
      result = star_wars_query(query_string, { "error" => "lazyRaisedError"})
      assert_equal 1, result["errors"].length
      assert_equal "lazy raised error from within connection", result["errors"][0]["message"]
    end

    it "adds an error for a raised error" do
      result = star_wars_query(query_string, { "error" => "raisedError"})
      assert_equal 1, result["errors"].length
      assert_equal "error raised from within connection", result["errors"][0]["message"]
    end
  end
end
