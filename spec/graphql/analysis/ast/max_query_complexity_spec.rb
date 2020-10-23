# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::AST::MaxQueryComplexity do
  let(:schema) { Class.new(Dummy::Schema) }
  let(:query_string) {%|
    {
      a: cheese(id: 1) { id }
      b: cheese(id: 1) { id }
      c: cheese(id: 1) { id }
      d: cheese(id: 1) { id }
      e: cheese(id: 1) { id }
    }
  |}
  let(:query) { GraphQL::Query.new(schema, query_string, variables: {}, max_complexity: max_complexity) }
  let(:result) {
    GraphQL::Analysis::AST.analyze_query(query, [GraphQL::Analysis::AST::MaxQueryComplexity]).first
  }


  describe "when a query goes over max complexity" do
    let(:max_complexity) { 9 }

    it "returns an error" do
      assert_equal GraphQL::AnalysisError, result.class
      assert_equal "Query has complexity of 10, which exceeds max complexity of 9", result.message
    end
  end

  describe "when there is no max complexity" do
    let(:max_complexity) { nil }

    it "doesn't error" do
      assert_nil result
    end
  end

  describe "when the query is less than the max complexity" do
    let(:max_complexity) { 99 }

    it "doesn't error" do
      assert_nil result
    end
  end

  describe "when max_complexity is decreased at query-level" do
    before do
      schema.max_complexity(100)
    end

    let(:max_complexity) { 7 }

    it "is applied" do
      assert_equal GraphQL::AnalysisError, result.class
      assert_equal "Query has complexity of 10, which exceeds max complexity of 7", result.message
    end
  end

  describe "when max_complexity is increased at query-level" do
    before do
      schema.max_complexity(1)
    end

    let(:max_complexity) { 10 }

    it "doesn't error" do
      assert_nil result
    end
  end

  describe "when max_complexity is nil at query-level" do
    let(:max_complexity) { nil }

    before do
      schema.max_complexity(1)
    end

    it "is applied" do
      assert_nil result
    end
  end

  describe "when used with the max_depth plugin" do
    let(:schema) do
      Class.new(GraphQL::Schema) do
        query Dummy::DairyAppQuery

        max_depth 3
        max_complexity 1
      end
    end

    let(:query_string) {%|
      {
        a: cheese(id: 1) { ...cheeseFields }
        b: cheese(id: 1) { ...cheeseFields }
        c: cheese(id: 1) { ...cheeseFields }
        d: cheese(id: 1) { ...cheeseFields }
        e: cheese(id: 1) { ...cheeseFields }
      }

      fragment cheeseFields on Cheese { id }
    |}
    let(:result) { schema.execute(query_string) }

    it "returns a complexity error" do
      assert_equal "Query has complexity of 10, which exceeds max complexity of 1", result["errors"].first["message"]
    end
  end

  describe "across a multiplex" do
    before do
      schema.analysis_engine = GraphQL::Analysis::AST
    end

    let(:queries) {
      5.times.map { |n|
        GraphQL::Query.new(schema, "{ cheese(id: #{n}) { id } }", variables: {})
      }
    }

    let(:max_complexity) { 9 }
    let(:multiplex) { GraphQL::Execution::Multiplex.new(schema: schema, queries: queries, context: {}, max_complexity: max_complexity) }
    let(:analyze_multiplex) {
      GraphQL::Analysis::AST.analyze_multiplex(multiplex, [GraphQL::Analysis::AST::MaxQueryComplexity])
    }

    it "returns errors for all queries" do
      analyze_multiplex
      err_msg = "Query has complexity of 10, which exceeds max complexity of 9"
      queries.each do |query|
        assert_equal err_msg, query.analysis_errors[0].message
      end
    end

    describe "with a local override" do
      let(:max_complexity) { 10 }

      it "uses the override" do
        analyze_multiplex

        queries.each do |query|
          assert query.analysis_errors.empty?
        end
      end
    end
  end
end
