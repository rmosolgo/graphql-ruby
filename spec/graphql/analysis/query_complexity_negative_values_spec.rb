# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::Analysis::QueryComplexity with negative values" do
  class NegativeComplexitySchema < GraphQL::Schema
    class Item < GraphQL::Schema::Object
      field :name, String
    end

    class Query < GraphQL::Schema::Object
      field :items, Item.connection_type
      field :counted, [Item], complexity: ->(ctx, args, child_complexity) { args[:count] * child_complexity } do
        argument :count, Int
      end
    end

    query(Query)
    default_max_page_size 50
  end

  SIBLINGS = "a: items(first: 50) { nodes { name } } b: items(first: 50) { nodes { name } }"

  def complexity_of(schema, query_str, variables = {})
    query = GraphQL::Query.new(schema, query_str, variables: variables)
    GraphQL::Analysis.analyze_query(query, [GraphQL::Analysis::QueryComplexity]).first
  end

  [:legacy, :future].each do |mode|
    describe "in #{mode} mode" do
      let(:schema) { Class.new(NegativeComplexitySchema) { complexity_cost_calculation_mode(mode) } }
      let(:siblings_complexity) { complexity_of(schema, "{ #{SIBLINGS} }") }
      let(:decoy_metadata_complexity) { complexity_of(schema, "{ decoy: items(first: 0) { nodes { name } } }") }

      it "counts a negative first: as an empty page, without reducing sibling costs" do
        assert_operator siblings_complexity, :>, 100
        assert_equal siblings_complexity + decoy_metadata_complexity, complexity_of(schema, "{ #{SIBLINGS} decoy: items(first: -1000000) { nodes { name } } }")
      end

      it "counts a negative first: from a variable as an empty page" do
        query_str = "query($n: Int) { #{SIBLINGS} decoy: items(first: $n) { nodes { name } } }"
        assert_equal siblings_complexity + decoy_metadata_complexity, complexity_of(schema, query_str, { "n" => -1_000_000 })
      end

      it "counts a negative last: as an empty page" do
        assert_equal siblings_complexity + decoy_metadata_complexity, complexity_of(schema, "{ #{SIBLINGS} decoy: items(last: -1000000) { nodes { name } } }")
      end

      it "uses the larger of first: and last: when one is negative" do
        assert_equal complexity_of(schema, "{ items(first: 10) { nodes { name } } }"), complexity_of(schema, "{ items(first: -5, last: 10) { nodes { name } } }")
      end

      it "doesn't let a negative custom complexity reduce sibling costs" do
        assert_equal siblings_complexity, complexity_of(schema, "{ #{SIBLINGS} counted(count: -1000000) { name } }")
      end
    end
  end

  it "rejects a query over max_complexity that has a negative first: decoy" do
    schema = Class.new(NegativeComplexitySchema) { max_complexity(100) }
    root = { items: [], counted: [] }
    result = schema.execute("query($n: Int) { #{SIBLINGS} decoy: items(first: $n) { nodes { name } } }", variables: { "n" => -1_000_000 }, root_value: root)
    assert_match(/exceeds max complexity of 100/, result.to_h.dig("errors", 0, "message").to_s)
  end
end
