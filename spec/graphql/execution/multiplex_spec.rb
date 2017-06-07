# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Multiplex do
  def multiplex(*a)
    LazyHelpers::LazySchema.multiplex(*a)
  end

  let(:q1) { <<-GRAPHQL
    query Q1 {
      nestedSum(value: 3) {
        value
        nestedSum(value: 7) {
          value
        }
      }
    }
    GRAPHQL
  }
  let(:q2) { <<-GRAPHQL
    query Q2 {
      nestedSum(value: 2) {
        value
        nestedSum(value: 11) {
          value
        }
      }
    }
    GRAPHQL
  }
  let(:q3) { <<-GRAPHQL
    query Q3 {
      listSum(values: [1,2]) {
        nestedSum(value: 3) {
          value
        }
      }
    }
    GRAPHQL
  }

  let(:queries) { [{query: q1}, {query: q2}, {query: q3}] }

  describe "multiple queries in the same lazy context" do
    it "runs multiple queries in the same lazy context" do
      expected_data = [
        {"data"=>{"nestedSum"=>{"value"=>14, "nestedSum"=>{"value"=>46}}}},
        {"data"=>{"nestedSum"=>{"value"=>14, "nestedSum"=>{"value"=>46}}}},
        {"data"=>{"listSum"=>[{"nestedSum"=>{"value"=>14}}, {"nestedSum"=>{"value"=>14}}]}},
      ]

      res = multiplex(queries)
      assert_equal expected_data, res
    end
  end

  describe "when some have validation errors or runtime errors" do
    let(:q1) { " { success: nullableNestedSum(value: 1) { value } }" }
    let(:q2) { " { runtimeError: nullableNestedSum(value: 13) { value } }" }
    let(:q3) { "{
      invalidNestedNull: nullableNestedSum(value: 1) {
        value
        nullableNestedSum(value: 2) {
          nestedSum(value: 13) {
            value
          }
          # This field will never get executed
          ns2: nestedSum(value: 13) {
            value
          }
        }
      }
    }" }
    let(:q4) { " { validationError: nullableNestedSum(value: true) }"}

    it "returns a mix of errors and values" do
      expected_res = [
        {
          "data"=>{"success"=>{"value"=>2}}
        },
        {
          "data"=>{"runtimeError"=>nil},
          "errors"=>[{
            "message"=>"13 is unlucky",
            "locations"=>[{"line"=>1, "column"=>4}],
            "path"=>["runtimeError"]
          }]
        },
        {
          "data"=>{"invalidNestedNull"=>{"value" => 2,"nullableNestedSum" => nil}},
          "errors"=>[{"message"=>"Cannot return null for non-nullable field LazySum.nestedSum"}],
        },
        {
          "errors" => [{
            "message"=>"Objects must have selections (field 'nullableNestedSum' returns LazySum but has no selections)",
            "locations"=>[{"line"=>1, "column"=>4}],
            "fields"=>["query", "validationError"]
          }]
        },
      ]

      res = multiplex([
        {query: q1},
        {query: q2},
        {query: q3},
        {query: q4},
      ])
      assert_equal expected_res, res
    end
  end

  describe "context shared by a multiplex run" do
    it "is provided as context:" do
      checks = []
      multiplex(queries, context: { instrumentation_checks: checks })
      assert_equal ["before multiplex 1", "before multiplex 2", "after multiplex 2", "after multiplex 1"], checks
    end
  end

  describe "instrumenting a multiplex run" do
    it "runs query instrumentation for each query and multiplex-level instrumentation" do
      checks = []
      queries_with_context = queries.map { |q| q.merge(context: { instrumentation_checks: checks }) }
      multiplex(queries_with_context, context: { instrumentation_checks: checks })
      assert_equal [
        "before multiplex 1",
        "before multiplex 2",
        "before Q1", "before Q2", "before Q3",
        "after Q1", "after Q2", "after Q3",
        "after multiplex 2",
        "after multiplex 1",
      ], checks
    end
  end
end
