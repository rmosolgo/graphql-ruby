require 'spec_helper'

describe GraphQL::Query::ParallelExecution do
  let(:result) { GraphQL::Query.new(SlowSchema, query_string).result }
  describe "fields that take a long time" do
    let(:query_string) {%|
      {
        slow1: slow { slow1, slow2, slows { slow1 } }
        slow2: slow { slow1, slow2, lastSlow: slow3 }
      }
    |}

    it "runs them in parallel, not in sequence" do
      elapsed = Benchmark.realtime { result }
      assert elapsed < 0.7, "It takes less that the sum of all sleeps"

      expected = { "data" => {
        "slow1" => { "slow1" => 1, "slow2" => 1, "slows" => [
            { "slow1" => 1 },
            { "slow1" => 1 },
            { "slow1" => 1 },
          ]
        },
        "slow2" => { "slow1" => 1, "slow2" => 1, "lastSlow" => 1},
      }}
      assert_equal expected, result, "It renders the right result"
    end
  end
end
