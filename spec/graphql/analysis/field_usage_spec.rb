# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::FieldUsage do
  let(:result) { [] }
  let(:field_usage_analyzer) { GraphQL::Analysis::FieldUsage.new { |query, used_fields, used_deprecated_fields| result << query << used_fields << used_deprecated_fields } }
  let(:reduce_result) { GraphQL::Analysis.analyze_query(query, [field_usage_analyzer]) }
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

    it "returns query in reduced result" do
      reduce_result
      assert_equal query, result[0]
    end

    it "keeps track of used fields" do
      reduce_result
      assert_equal ['Cheese.id', 'Cheese.fatContent', 'Query.cheese'], result[1]
    end

    it "keeps track of deprecated fields" do
      reduce_result
      assert_equal ['Cheese.fatContent'], result[2]
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
      reduce_result
      assert_equal ['Cheese.id', 'Cheese.fatContent', 'Query.cheese'], result[1]
    end

    it "omits duplicate usage of a deprecated field" do
      reduce_result
      assert_equal ['Cheese.fatContent'], result[2]
    end
  end
end
