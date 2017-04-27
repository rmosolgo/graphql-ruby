# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Multiplex do
  def multiplex(queries)
    LazyHelpers::LazySchema.multiplex(queries)
  end

  describe "multiple queries in the same lazy context" do
    let(:q1) { <<-GRAPHQL
      {
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
      {
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
      {
        listSum(values: [1,2]) {
          nestedSum(value: 3) {
            value
          }
        }
      }
    GRAPHQL
    }

    it "runs multiple queries in the same lazy context" do
      expected_data = [
        {"data"=>{"nestedSum"=>{"value"=>14, "nestedSum"=>{"value"=>46}}}},
        {"data"=>{"nestedSum"=>{"value"=>14, "nestedSum"=>{"value"=>46}}}},
        {"data"=>{"listSum"=>[{"nestedSum"=>{"value"=>14}}, {"nestedSum"=>{"value"=>14}}]}},
      ]

      queries = [
        {query: q1},
        {query: q2},
        {query: q3},
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
        }
      }
    }" }
    let(:q4) { " { validationError: nullableNestedSum(value: true) }"}

    it "handles errors in instrumentation"

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

      queries = [
        {query: q1},
        {query: q2},
        {query: q3},
        {query: q4},
      ]

      res = multiplex(queries)
      assert_equal expected_res, res
    end
  end

  describe "context shared by a multiplex run" do
    it "exists or something"
  end

  describe "instrumenting a multiplex run" do
    it "runs query instrumentation for each query"
    it "runs multiplex-level instrumentation"
  end
end
