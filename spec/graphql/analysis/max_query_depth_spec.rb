# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::MaxQueryDepth do
  before do
    @prev_max_depth = Dummy::Schema.max_depth
  end

  after do
    Dummy::Schema.max_depth = @prev_max_depth
  end

  let(:result) { Dummy::Schema.execute(query_string) }
  let(:query_string) { "
    {
      cheese(id: 1) {
        similarCheese(source: SHEEP) {
          similarCheese(source: SHEEP) {
            similarCheese(source: SHEEP) {
              similarCheese(source: SHEEP) {
                similarCheese(source: SHEEP) {
                  id
                }
              }
            }
          }
        }
      }
    }
  "}

  describe "when the query is deeper than max depth" do
    it "adds an error message for a too-deep query" do
      assert_equal "Query has depth of 7, which exceeds max depth of 5", result["errors"][0]["message"]
    end
  end

  describe "when the query specifies a different max_depth" do
    let(:result) { Dummy::Schema.execute(query_string, max_depth: 100) }

    it "obeys that max_depth" do
      assert_nil result["errors"]
    end
  end

  describe "When the query is not deeper than max_depth" do
    before do
      Dummy::Schema.max_depth = 100
    end

    it "doesn't add an error" do
      assert_nil result["errors"]
    end
  end

  describe "when the max depth isn't set" do
    before do
      Dummy::Schema.max_depth = nil
    end

    it "doesn't add an error message" do
      assert_nil result["errors"]
    end
  end

  describe "when a fragment exceeds max depth" do
    before do
      Dummy::Schema.max_depth = 4
    end

    let(:query_string) { "
      {
        cheese(id: 1) {
          ...moreFields
        }
      }

      fragment moreFields on Cheese {
        similarCheese(source: SHEEP) {
          similarCheese(source: SHEEP) {
            similarCheese(source: SHEEP) {
              ...evenMoreFields
            }
          }
        }
      }

      fragment evenMoreFields on Cheese {
        similarCheese(source: SHEEP) {
          similarCheese(source: SHEEP) {
            id
          }
        }
      }
    "}

    it "adds an error message for a too-deep query" do
      assert_equal 1, result["errors"].length
    end
  end
end
