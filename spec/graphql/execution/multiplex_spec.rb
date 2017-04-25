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
      # TODO This is required because multiplex doesn't properly run instrumentation
      LazyHelpers::SumAll.all.clear

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
    it "returns a mix of errors and values"
  end

  describe "context shared by a multiplex run" do
    it "exists or something"
  end

  describe "instrumenting a multiplex run" do
    it "runs query instrumentation for each query"
    it "runs multiplex-level instrumentation"
  end
end
