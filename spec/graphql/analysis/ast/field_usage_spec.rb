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

  describe "query with deprecated arguments" do
    let(:query_string) {%|
      query {
        fromSource(oldSource: "deprecated") {
          id
        }
      }
    |}

    it "keeps track of deprecated arguments" do
      assert_equal ['Query.fromSource.oldSource'], result[:used_deprecated_arguments]
    end
  end

  describe "query with deprecated arguments used more than once" do
    let(:query_string) {%|
      query {
        fromSource(oldSource: "deprecated1") {
          id
        }

        fromSource(oldSource: "deprecated2") {
          id
        }
      }
    |}

    it "omits duplicate usage of a deprecated argument" do
      assert_equal ['Query.fromSource.oldSource'], result[:used_deprecated_arguments]
    end
  end

  describe "query with deprecated arguments nested in an array argument" do
    let(:query_string) {%|
      query {
        searchDairy(product: [{ oldSource: "deprecated" }]) {
          __typename
        }
      }
    |}

    it "keeps track of nested deprecated arguments" do
      assert_equal ['DairyProductInput.oldSource'], result[:used_deprecated_arguments]
    end
  end

  describe "query with an array argument sent as null" do
    let(:query_string) {%|
      query {
        searchDairy(product: null) {
          __typename
        }
      }
    |}

    it "tolerates null for array argument" do
      result
    end
  end

  describe "query with an input object sent in as null" do
    let(:query_string) {%|
      query {
        cheese(id: 1) {
          id
          dairyProduct(input: null) {
            __typename
          }
        }
      }
    |}

    it "tolerates null for object argument" do
      result
    end
  end

  describe "query with deprecated arguments nested in an argument" do
    let(:query_string) {%|
      query {
        searchDairy(singleProduct: { oldSource: "deprecated" }) {
          __typename
        }
      }
    |}

    it "keeps track of nested deprecated arguments" do
      assert_equal ['DairyProductInput.oldSource'], result[:used_deprecated_arguments]
    end
  end

  describe "query with arguments nested in a deprecated argument" do
    let(:query_string) {%|
      query {
        searchDairy(oldProduct: [{ source: "sheep" }]) {
          __typename
        }
      }
    |}

    it "keeps track of top-level deprecated arguments" do
      assert_equal ['Query.searchDairy.oldProduct'], result[:used_deprecated_arguments]
    end
  end

  describe "query with scalar arguments nested in a deprecated argument" do
    let(:query_string) {%|
      query {
        searchDairy(productIds: ["123"]) {
          __typename
        }
      }
    |}

    it "keeps track of top-level deprecated arguments" do
      assert_equal ['Query.searchDairy.productIds'], result[:used_deprecated_arguments]
    end
  end

  describe "when an argument prepare raises a GraphQL::ExecutionError" do
    class ArgumentErrorFieldUsageSchema < GraphQL::Schema
      class FieldUsage < GraphQL::Analysis::AST::FieldUsage
        def result
          values = super
          query.context[:field_usage] = values
          nil
        end
      end

      class Query < GraphQL::Schema::Object
        field :f, Int do
          argument :i, Int, prepare: ->(*) { raise GraphQL::ExecutionError.new("boom!") }
        end
      end

      query(Query)
      query_analyzer(FieldUsage)
    end

    it "skips analysis of those arguments" do
      res = ArgumentErrorFieldUsageSchema.execute("{ f(i: 1) }")
      assert_equal ["boom!"], res["errors"].map { |e| e["message"] }
      assert_equal({used_fields: ["Query.f"], used_deprecated_arguments: [], used_deprecated_fields: []}, res.context[:field_usage])
    end
  end
end
