# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::MaxQueryComplexity do
  before do
    @prev_max_complexity = Dummy::Schema.max_complexity
  end

  after do
    Dummy::Schema.max_complexity = @prev_max_complexity
  end


  let(:result) { Dummy::Schema.execute(query_string) }
  let(:query_string) {%|
    {
      a: cheese(id: 1) { id }
      b: cheese(id: 1) { id }
      c: cheese(id: 1) { id }
      d: cheese(id: 1) { id }
      e: cheese(id: 1) { id }
    }
  |}

  describe "when a query goes over max complexity" do
    before do
      Dummy::Schema.max_complexity = 9
    end

    it "returns an error" do
      assert_equal "Query has complexity of 10, which exceeds max complexity of 9", result["errors"][0]["message"]
    end
  end

  describe "when there is no max complexity" do
    before do
      Dummy::Schema.max_complexity = nil
    end
    it "doesn't error" do
      assert_nil result["errors"]
    end
  end

  describe "when the query is less than the max complexity" do
    before do
      Dummy::Schema.max_complexity = 99
    end
    it "doesn't error" do
      assert_nil result["errors"]
    end
  end

  describe "when max_complexity is decreased at query-level" do
    before do
      Dummy::Schema.max_complexity = 100
    end
    let(:result) { Dummy::Schema.execute(query_string, max_complexity: 7) }

    it "is applied" do
      assert_equal "Query has complexity of 10, which exceeds max complexity of 7", result["errors"][0]["message"]
    end
  end

  describe "when max_complexity is increased at query-level" do
    before do
      Dummy::Schema.max_complexity = 1
    end
    let(:result) { Dummy::Schema.execute(query_string, max_complexity: 10) }

    it "doesn't error" do
      assert_nil result["errors"]
    end
  end

  describe "across a multiplex" do
    before do
      Dummy::Schema.max_complexity = 9
    end

    let(:queries) { 5.times.map { |n|  { query: "{ cheese(id: #{n}) { id } }" } } }

    it "returns errors for all queries" do
      results = Dummy::Schema.multiplex(queries)
      assert_equal 5, results.length
      err_msg = "Query has complexity of 10, which exceeds max complexity of 9"
      results.each do |res|
        assert_equal err_msg, res["errors"][0]["message"]
      end
    end

    describe "with a local override" do
      it "uses the override" do
        results = Dummy::Schema.multiplex(queries, max_complexity: 10)
        assert_equal 5, results.length
        results.each do |res|
          assert_equal true, res.key?("data")
          assert_equal false, res.key?("errors")
        end
      end
    end
  end
end
