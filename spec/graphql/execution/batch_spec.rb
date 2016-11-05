require "spec_helper"

describe GraphQL::Execution::Batch do
  LOADS = []

  module MultiplyLoader
    def self.call(factor, ints)
      LOADS << ints
      ints.each do |int|
        yield(int, int * factor)
      end
    end
  end

  BatchQueryType = GraphQL::ObjectType.define do
    name "Query"
    field :int, types.Int do
      argument :value, types.Int
      batch_resolve MultiplyLoader, 1, -> (_obj, args, ctx) {
        # It's ok to not pass a block
        ctx.batch(args[:value])
      }
    end

    field :batchInt, BatchIntType do
      argument :value, types.Int
      batch_resolve MultiplyLoader, 2, -> (_obj, args, ctx) {
        ctx.batch(args[:value]) { |v| OpenStruct.new(val: v, query: :q) }
      }
    end

    field :self, BatchQueryType, resolve: ->(o, a, c) { :q }
    field :selfs, types[BatchQueryType] do
      argument :count, types.Int
      resolve ->(o, args, c) { args[:count].times.map { :q } }
    end
  end

  BatchIntType = GraphQL::ObjectType.define do
    name "BatchInt"
    field :val, types.Int
    field :query, BatchQueryType
  end

  BatchSchema = GraphQL::Schema.define do
    query(BatchQueryType)
    directives(["defer", "stream"])
    query_execution_strategy(GraphQL::Execution::DeferredExecution)
  end

  before do
    LOADS.clear
  end

  describe "batch resolving" do
    it "makes one load with all values" do
      res = BatchSchema.execute(%|
        {
          one: int(value: 1)
          two: int(value: 2)
          self {
            three: int(value: 3)
            three2: int(value: 3)
          }
        }
      |)

      assert_equal [[1,2,3]], LOADS, "It called the loader once"
      expected_data = {
        "one" => 1,
        "two" => 2,
        "self" => {
          "three" => 3,
          "three2" => 3
        }
      }
      assert_equal expected_data, res["data"], "The loader modified values"
    end
  end

  describe "nested batch resolving" do
    it "makes multiple batches" do
      res = BatchSchema.execute(%|
        {
          one: int(value: 1),
          two: int(value: 2),
          six: batchInt(value: 6) {
            val
            query {
              three: int(value: 3)
              four: int(value: 4)
            }
          }
          seven: batchInt(value: 7) {
            val
            query {
              five: int(value: 5)
            }
          }
        }
      |)

      assert_equal [[1,2], [6,7], [3,4,5]], LOADS, "It called the loader multiple times"

      expected_data = {
        "one" => 1,
        "two" => 2,
        "six" => {
          "val" => 12,
          "query" => {
            "three" => 3,
            "four" => 4,
          }
        },
        "seven" => {
          "val" => 14,
          "query" => {
            "five" => 5,
          }
        }
      }
      assert_equal expected_data, res["data"], "It applies different loaders"
    end
  end

  describe "deferred batch resolving" do
    it "does deferred batches" do
      res = BatchSchema.execute(%|
        {
          one: batchInt(value: 1) {
            val
          }
          two: batchInt(value: 2) @defer {
            val
            query {
              three: int(value: 3)
              four: int(value: 4)
            }
          }
          five: batchInt(value: 5) @defer {
            val
            query {
              six: int(value: 6)
            }
          }
        }
      |)
      assert_equal [[1], [2], [3,4], [5], [6]], LOADS
      expected_data = {
        "one"=>{"val"=>2},
        "two"=>{"val"=>4, "query"=>{"three"=>3, "four"=>4}},
        "five"=>{"val"=>10, "query"=>{"six"=>6}},
      }
      assert_equal expected_data, res["data"]
    end
  end

  describe "streamed batches" do
    it "loads them one at a time" do
      res = BatchSchema.execute(%|
        {
          selfs(count: 3) @stream {
            t: __typename
            one: int(value: 1)
            two: int(value: 2)
          }
        }
      |)

      pp res

      expected_loads = [[1,2], [1,2], [1,2]]
      assert_equal expected_loads, LOADS

      expected_data = {
        "selfs"=> [
          {"t" => "Query", "one"=>1, "two"=>2},
          {"t" => "Query", "one"=>1, "two"=>2},
          {"t" => "Query", "one"=>1, "two"=>2},
        ]
      }
      assert_equal expected_data, res["data"]
    end
  end

  describe "yielding errors in batches" do
    it "treats it like a returned error"
  end
end
