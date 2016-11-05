require "spec_helper"

describe GraphQL::Execution::Batch do
  LOADS = []

  module MultiplyLoader
    def self.call(factor, ints)
      LOADS << ints
      ints.each do |int|
        if int == 99
          yield(int, GraphQL::ExecutionError.new("99 is forbidden"))
        else
          yield(int, int * factor)
        end
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

    field :reqBatchInt, !ReqBatchIntType do
      argument :value, types.Int
      batch_resolve MultiplyLoader, 3, -> (_obj, args, ctx) {
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

  ReqBatchIntType = GraphQL::ObjectType.define do
    name "ReqBatchInt"
    field :val, !types.Int
  end


  BatchSchema = GraphQL::Schema.define do
    query(BatchQueryType)
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

  describe "nested batch fields" do
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

      assert_equal [[1,2], [6,7], [3,4,5]], LOADS

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
      assert_equal expected_data, res["data"]
    end
  end


  describe "yielding errors in batches" do
    it "treats it like a returned error" do
      res = BatchSchema.execute(%|
        {
          one: int(value: 1)
          two: batchInt(value: 2) {
            val
            query {
              err: int(value: 99)
            }
          }
        }
      |)

      expected_data = {
        "one"=>1,
        "two"=>{
          "val"=>4,
          "query"=>{
            "err"=>nil
          }
        }
      }

      expected_errors = [
        {
          "message"=>"99 is forbidden",
          "locations"=>[{"line"=>7, "column"=>15}],
          "path"=>["two", "query", "err"]
        }
      ]
      assert_equal expected_data, res["data"]
      assert_equal expected_errors, res["errors"]
    end

    it "propagates invalid nulls" do
      res = BatchSchema.execute(%|
        {
          one: int(value: 1)
          two: reqBatchInt(value: 99) {
            val
          }
        }
      |)

      pp res
      expected_data = {}
      assert_equal expected_data, res["data"]
      expected_errors = []
      assert_equal expected_errors, res["errors"]
    end
  end
end
