# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::AST::MaxQueryDepth do
  let(:schema) {
    schema = Class.new(Dummy::Schema)
    schema.analysis_engine = GraphQL::Analysis::AST
    schema
  }
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
  let(:max_depth) { nil }
  let(:query) {
    GraphQL::Query.new(
      schema.graphql_definition,
      query_string,
      variables: {},
      max_depth: max_depth
    )
  }
  let(:result) {
    GraphQL::Analysis::AST.analyze_query(query, [GraphQL::Analysis::AST::MaxQueryDepth]).first
  }
  let(:multiplex) {
    GraphQL::Execution::Multiplex.new(
      schema: schema,
      queries: [query.dup, query.dup],
      context: {},
      max_complexity: nil
    )
  }
  let(:multiplex_result) {
    GraphQL::Analysis::AST.analyze_multiplex(multiplex, [GraphQL::Analysis::AST::MaxQueryDepth]).first
  }

  describe "when the query is deeper than max depth" do
    let(:max_depth) { 5 }

    it "adds an error message for a too-deep query" do
      assert_equal "Query has depth of 7, which exceeds max depth of 5", result.message
    end
  end

  describe "when a multiplex queries is deeper than max depth" do
    before do
      schema.max_depth = 5
    end

    it "adds an error message for a too-deep query on from multiplex analyzer" do
      assert_equal "Query has depth of 7, which exceeds max depth of 5", multiplex_result.message
    end
  end

  describe "when the query specifies a different max_depth" do
    let(:max_depth) { 100 }

    it "obeys that max_depth" do
      assert_nil result
    end
  end

  describe "When the query is not deeper than max_depth" do
    before do
      schema.max_depth = 100
    end

    it "doesn't add an error" do
      assert_nil result
    end
  end

  describe "when the max depth isn't set" do
    before do
      schema.max_depth = nil
    end

    it "doesn't add an error message" do
      assert_nil result
    end
  end

  describe "when a fragment exceeds max depth" do
    before do
      schema.max_depth = 4
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
      assert_equal "Query has depth of 7, which exceeds max depth of 4", result.message
    end
  end
end
