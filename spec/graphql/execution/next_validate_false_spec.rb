# frozen_string_literal: true
require "spec_helper"

describe "Next Execution with validate: false" do
  class NextValidateFalseSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      field :items, [String], complexity: ->(_ctx, args, child_complexity) { args[:count] * [child_complexity, 1].max } do
        argument :count, Int
      end
      field :nested, Query
    end

    Root = Struct.new(:resolved) do
      def items(count:)
        resolved << count
        Array.new([count, 3].min) { "x" }
      end

      def nested
        self
      end
    end

    query(Query)
    max_complexity(100)
    max_depth(3)
    complexity_cost_calculation_mode(:future)
    use GraphQL::Execution::Next
  end

  def run_query(method_name, query_str, **options)
    root = NextValidateFalseSchema::Root.new([])
    result = NextValidateFalseSchema.public_send(method_name, query_str, validate: false, root_value: root, **options).to_h
    [result, root.resolved]
  end

  [:execute, :execute_next].each do |method_name|
    describe "with #{method_name}" do
      it "enforces max_complexity" do
        result, resolved = run_query(method_name, "query($n: Int!) { items(count: $n) }", variables: { "n" => 100_000 })
        assert_equal ["Query has complexity of 100000, which exceeds max complexity of 100"], result["errors"].map { |e| e["message"] }
        refute result.key?("data")
        assert_equal [], resolved
      end

      it "enforces max_depth" do
        result, resolved = run_query(method_name, "{ nested { nested { nested { nested { items(count: 1) } } } } }")
        assert_equal ["Query has depth of 5, which exceeds max depth of 3"], result["errors"].map { |e| e["message"] }
        assert_equal [], resolved
      end

      it "rejects invalid variables" do
        ["not-an-int", nil].each do |value|
          result, resolved = run_query(method_name, "query($n: Int!) { items(count: $n) }", variables: { "n" => value })
          assert_equal 1, result["errors"].size
          assert_includes result["errors"][0]["message"], "Variable $n of type Int! was provided invalid value"
          assert_equal [], resolved
        end
      end

      it "rejects an unknown operation name" do
        result, resolved = run_query(method_name, "query A { items(count: 1) }", operation_name: "Nope")
        assert_equal ['No operation named "Nope"'], result["errors"].map { |e| e["message"] }
        assert_equal [], resolved
      end

      it "returns an empty result for a document without operations" do
        result, resolved = run_query(method_name, "fragment F on Query { items(count: 1) }")
        assert_equal({}, result)
        assert_equal [], resolved
      end

      it "runs queries within the limits" do
        result, resolved = run_query(method_name, "query($n: Int!) { items(count: $n) nested { items(count: 2) } }", variables: { "n" => 5 })
        assert_equal({ "data" => { "items" => ["x", "x", "x"], "nested" => { "items" => ["x", "x"] } } }, result)
        assert_equal [5, 2], resolved
      end
    end
  end
end
