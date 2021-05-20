# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Dataloader::AsyncDataloader do
  class AsyncSchema < GraphQL::Schema
    class SleepSource < GraphQL::Dataloader::Source
      def fetch(keys)
        max_sleep = keys.max
        `sleep #{max_sleep}`
        keys.map { |_k| max_sleep }
      end
    end

    class Query < GraphQL::Schema::Object
      field :sleep, Float, null: false do
        argument :duration, Float, required: true
      end

      def sleep(duration:)
        `sleep #{duration}`
        duration
      end
    end

    query(Query)
    use GraphQL::Dataloader::AsyncDataloader
  end

  it "runs IO in parallel by default" do
    dataloader = GraphQL::Dataloader::AsyncDataloader.new
    results = {}
    dataloader.append_job { `sleep 0.1`; results[:a] = 1 }
    dataloader.append_job { `sleep 0.2`; results[:b] = 2 }
    dataloader.append_job { `sleep 0.3`; results[:c] = 3 }

    assert_equal({}, results, "Nothing ran yet")
    started_at = Time.now
    dataloader.run
    ended_at = Time.now

    assert_equal({ a: 1, b: 2, c: 3 }, results, "All the jobs ran")
    assert_in_delta 0.3, ended_at - started_at, 0.05, "IO ran in parallel"
  end

  it "works with sources" do
    dataloader = GraphQL::Dataloader::AsyncDataloader.new
    r1 = dataloader.with(AsyncSchema::SleepSource).request(0.1)
    r2 = dataloader.with(AsyncSchema::SleepSource).request(0.2)
    r3 = dataloader.with(AsyncSchema::SleepSource).request(0.3)

    v1 = nil
    dataloader.append_job {
      v1 = r1.load
    }
    started_at = Time.now
    dataloader.run
    ended_at = Time.now
    assert_equal 0.3, v1
    started_at_2 = Time.now
    # These should take no time at all since they're already resolved
    v2 = r2.load
    v3 = r3.load
    ended_at_2 = Time.now

    assert_equal 0.3, v2
    assert_equal 0.3, v3
    assert_in_delta 0.0, started_at_2 - ended_at_2, 0.05, "Already-loaded values returned instantly"

    assert_in_delta 0.3, ended_at - started_at, 0.05, "IO ran in parallel"
  end

  it "works with GraphQL" do
    started_at = Time.now
    res = AsyncSchema.execute("{ s1: sleep(duration: 0.1) s2: sleep(duration: 0.2) s3: sleep(duration: 0.3) }")
    ended_at = Time.now
    assert_equal({"s1"=>0.1, "s2"=>0.2, "s3"=>0.3}, res["data"])
    assert_in_delta 0.3, ended_at - started_at, 0.05, "IO ran in parallel"
  end
end
