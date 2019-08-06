# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::QueryDepth do
  let(:depths) { [] }
  let(:query_depth) { GraphQL::Analysis::QueryDepth.new { |query, max_depth|  depths << query << max_depth } }
  let(:reduce_result) { GraphQL::Analysis.analyze_query(query, [query_depth]) }
  let(:query) { GraphQL::Query.new(Dummy::Schema, query_string, variables: variables) }
  let(:variables) { {} }

  describe "simple queries" do
    let(:query_string) {%|
      query cheeses($isIncluded: Boolean = true){
        # depth of 2
        cheese1: cheese(id: 1) {
          id
          flavor
        }

        # depth of 4
        cheese2: cheese(id: 2) @include(if: $isIncluded) {
          similarCheese(source: SHEEP) {
            ... on Cheese {
              similarCheese(source: SHEEP) {
                id
              }
            }
          }
        }
      }
    |}

    it "finds the max depth" do
      reduce_result
      assert_equal depths, [query, 4]
    end

    describe "with directives" do
      let(:variables) { { "isIncluded" => false } }
      it "doesn't count skipped fields" do
        reduce_result
        assert_equal depths.last, 2
      end
    end
  end

  describe "query with fragments" do
    let(:query_string) {%|
      {
        # depth of 2
        cheese1: cheese(id: 1) {
          id
          flavor
        }

        # depth of 4
        cheese2: cheese(id: 2) {
          ... cheeseFields1
        }
      }

      fragment cheeseFields1 on Cheese {
        similarCheese(source: COW) {
          id
          ... cheeseFields2
        }
      }

      fragment cheeseFields2 on Cheese {
        similarCheese(source: SHEEP) {
          id
        }
      }
    |}

    it "finds the max depth" do
      reduce_result
      assert_equal depths, [query, 4]
    end
  end
end
