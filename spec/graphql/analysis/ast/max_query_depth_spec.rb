# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::AST::MaxQueryDepth do
  let(:schema) { Class.new(Dummy::Schema) }
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
  let(:query) { GraphQL::Query.new(schema, query_string) }
  let(:result) {
    GraphQL::Analysis::AST.analyze_query(query, [GraphQL::Analysis::AST::MaxQueryDepth]).first
  }

  describe "when the query is deeper than max depth" do
    it "adds an error message for a too-deep query" do
      assert_equal "Query has depth of 7, which exceeds max depth of 5", result.message
    end
  end

  describe "when the query specifies a different max_depth" do
    let(:query) { GraphQL::Query.new(schema, query_string, max_depth: 100) }

    it "obeys that max_depth" do
      assert_nil result
    end
  end

  describe "when the query disables max_depth" do
    let(:query) { GraphQL::Query.new(schema, query_string, max_depth: nil) }

    it "obeys that max_depth" do
      assert_nil result
    end
  end

  describe "When the query includes introspective fields" do
    let(:query_string) { "
    query allSchemaTypes {
      __schema {
         types {
            fields {
              type {
                fields {
                  type {
                    fields {
                      type {
                        name
                      }
                    }
                  }
                }
              }
            }
         }
      }
    }
  "}

    it "adds an error message for a too-deep query" do
      assert_equal "Query has depth of 9, which exceeds max depth of 5", result.message
    end
  end

  describe "When the query is not deeper than max_depth" do
    before do
      schema.max_depth(100)
    end

    it "doesn't add an error" do
      assert_nil result
    end
  end

  describe "when the max depth isn't set" do
    before do
      # Yuck - Can't override GraphQL::Schema.max_depth to return nil if it has already been set
      schema.define_singleton_method(:max_depth) { |*| nil }
    end

    it "doesn't add an error message" do
      assert_nil result
    end
  end

  describe "when a fragment exceeds max depth" do
    before do
      schema.max_depth(4)
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
