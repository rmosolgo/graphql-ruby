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
      assert_equal nil, result["errors"]
    end
  end

  describe "when the query is less than the max complexity" do
    before do
      Dummy::Schema.max_complexity = 99
    end
    it "doesn't error" do
      assert_equal nil, result["errors"]
    end
  end

  describe "when complexity is overriden at query-level" do
    before do
      Dummy::Schema.max_complexity = 100
    end
    let(:result) { Dummy::Schema.execute(query_string, max_complexity: 7) }

    it "is applied" do
      assert_equal "Query has complexity of 10, which exceeds max complexity of 7", result["errors"][0]["message"]
    end
  end
end
