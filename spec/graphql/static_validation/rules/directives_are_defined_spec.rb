# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::DirectivesAreDefined do
  include StaticValidationHelpers
  let(:query_string) {"
    query getCheese {
      okCheese: cheese(id: 1) {
        id @skip(if: true),
        source @nonsense(if: false)
        ... on Cheese {
          flavor @moreNonsense
        }
      }
    }
  "}
  describe "non-existent directives" do
    it "makes errors for them" do
      expected = [
        {
          "message"=>"Directive @nonsense is not defined",
          "locations"=>[{"line"=>5, "column"=>16}],
          "fields"=>["query getCheese", "okCheese", "source"],
        }, {
          "message"=>"Directive @moreNonsense is not defined",
          "locations"=>[{"line"=>7, "column"=>18}],
          "fields"=>["query getCheese", "okCheese", "... on Cheese", "flavor"],
        }
      ]
      assert_equal(expected, errors)
    end
  end
end
