# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Dataloader::AsyncDataloader do
  class AsyncSchema < GraphQL::Schema
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
    dataloader.append_job { `sleep 1`; p results[:a] = 1 }
    dataloader.append_job { `sleep 2`; p results[:b] = 2 }
    dataloader.append_job { `sleep 3`; p results[:c] = 3 }

    assert_equal({}, results, "Nothing ran yet")
    started_at = Time.now
    dataloader.run
    ended_at = Time.now

    assert_equal({ a: 1, b: 2, c: 3 }, results, "All the jobs ran")
    assert_in_delta 3, ended_at - started_at, 0.2, "IO ran in parallel"
  end

  it "works with GraphQL" do
    started_at = Time.now
    res = AsyncSchema.execute("{ s1: sleep(duration: 1) s2: sleep(duration: 2) s3: sleep(duration: 3) }")
    ended_at = Time.now
    assert_equal({"s1"=>1.0, "s2"=>2.0, "s3"=>3.0}, res["data"])
    assert_in_delta 3, ended_at - started_at, 0.2, "IO ran in parallel"
  end
end
