# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::AST::FieldUsage do
  let(:result) { GraphQL::Analysis::AST.analyze_query(query, [GraphQL::Analysis::AST::FieldUsage]).first }
  let(:query) { GraphQL::Query.new(Dummy::Schema, query_string, variables: variables) }
  let(:variables) { {} }

  describe "query with deprecated fields" do
    let(:query_string) {%|
      query {
        cheese(id: 1) {
          id
          fatContent
        }
      }
    |}

    it "keeps track of used fields" do
      assert_equal ['Cheese.id', 'Cheese.fatContent', 'Query.cheese'], result[:used_fields]
    end

    it "keeps track of deprecated fields" do
      assert_equal ['Cheese.fatContent'], result[:used_deprecated_fields]
    end
  end

  describe "query with deprecated fields used more than once" do
    let(:query_string) {%|
      query {
        cheese1: cheese(id: 1) {
          id
          fatContent
        }

        cheese2: cheese(id: 2) {
          id
          fatContent
        }
      }
    |}

    it "omits duplicate usage of a field" do
      assert_equal ['Cheese.id', 'Cheese.fatContent', 'Query.cheese'], result[:used_fields]
    end

    it "omits duplicate usage of a deprecated field" do
      assert_equal ['Cheese.fatContent'], result[:used_deprecated_fields]
    end
  end

  describe "query with deprecated fields in a fragment" do
    let(:query_string) {%|
      query {
        cheese(id: 1) {
         id
         ...CheeseSelections
        }
      }
      fragment CheeseSelections on Cheese {
        fatContent
      }
    |}

    it "keeps track of fields used in the fragment" do
      assert_equal ['Cheese.id', 'Cheese.fatContent', 'Query.cheese'], result[:used_fields]
    end

    it "keeps track of deprecated fields used in the fragment" do
      assert_equal ['Cheese.fatContent'], result[:used_deprecated_fields]
    end
  end

  describe "query with deprecated fields in an inline fragment" do
    let(:query_string) {%|
      query {
        cheese(id: 1) {
         id
         ... on Cheese {
           fatContent
         }
        }
      }
    |}

    it "keeps track of fields used in the fragment" do
      assert_equal ['Cheese.id', 'Cheese.fatContent', 'Query.cheese'], result[:used_fields]
    end

    it "keeps track of deprecated fields used in the fragment" do
      assert_equal ['Cheese.fatContent'], result[:used_deprecated_fields]
    end
  end
end
