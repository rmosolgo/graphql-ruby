# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::TimeoutMiddleware do
  let(:max_seconds) { 1 }
  let(:timeout_middleware) {  GraphQL::Schema::TimeoutMiddleware.new(max_seconds: max_seconds) }
  let(:timeout_schema) {

    sleep_for_seconds_resolve = ->(obj, args, ctx) {
      sleep(args[:seconds])
      args[:seconds]
    }

    nested_sleep_type = GraphQL::ObjectType.define do
      name "NestedSleep"
      field :seconds, types.Float do
        resolve ->(obj, args, ctx) { obj }
      end

      field :nestedSleep, -> { nested_sleep_type } do
        argument :seconds, !types.Float
        resolve(sleep_for_seconds_resolve)
      end
    end

    query_type = GraphQL::ObjectType.define do
      name "Query"
      field :sleepFor, types.Float do
        argument :seconds, !types.Float
        resolve(sleep_for_seconds_resolve)
      end

      field :nestedSleep, nested_sleep_type do
        argument :seconds, !types.Float
        resolve(sleep_for_seconds_resolve)
      end
    end

    schema = GraphQL::Schema.define(query: query_type)
    schema.middleware << timeout_middleware
    schema
  }

  let(:result) { timeout_schema.execute(query_string) }

  describe "timeout part-way through" do
    let(:query_string) {%|
      {
        a: sleepFor(seconds: 0.4)
        b: sleepFor(seconds: 0.4)
        c: sleepFor(seconds: 0.4)
        d: sleepFor(seconds: 0.4)
        e: sleepFor(seconds: 0.4)
      }
    |}
    it "returns a partial response and error messages" do
      expected_data = {
        "a"=>0.4,
        "b"=>0.4,
        "c"=>0.4,
        "d"=>nil,
        "e"=>nil,
      }

      expected_errors =  [
        {
          "message"=>"Timeout on Query.sleepFor",
          "locations"=>[{"line"=>6, "column"=>9}],
          "path"=>["d"]
        },
        {
          "message"=>"Timeout on Query.sleepFor",
          "locations"=>[{"line"=>7, "column"=>9}],
          "path"=>["e"]
        },
      ]
      assert_equal expected_data, result["data"]
      assert_equal expected_errors, result["errors"]
    end
  end

  describe "timeout in nested fields" do
    let(:query_string) {%|
    {
      a: nestedSleep(seconds: 0.3) {
        seconds
        b: nestedSleep(seconds: 0.3) {
          seconds
          c: nestedSleep(seconds: 0.3) {
            seconds
            d: nestedSleep(seconds: 0.4) {
              seconds
              e: nestedSleep(seconds: 0.4) {
                seconds
              }
            }
          }
        }
      }
    }
    |}

    it "returns a partial response and error messages" do
      expected_data = {
        "a" => {
          "seconds" => 0.3,
          "b" => {
            "seconds" => 0.3,
            "c" => {
              "seconds"=>0.3,
              "d" => {
                "seconds"=>nil,
                "e"=>nil
              }
            }
          }
        }
      }
      expected_errors = [
        {
          "message"=>"Timeout on NestedSleep.seconds",
          "locations"=>[{"line"=>10, "column"=>15}],
          "path"=>["a", "b", "c", "d", "seconds"]
        },
        {
          "message"=>"Timeout on NestedSleep.nestedSleep",
          "locations"=>[{"line"=>11, "column"=>15}],
          "path"=>["a", "b", "c", "d", "e"]
        },
      ]

      assert_equal expected_data, result["data"]
      assert_equal expected_errors, result["errors"]
    end
  end

  describe "long-running fields" do
    let(:query_string) {%|
      {
        a: sleepFor(seconds: 0.2)
        b: sleepFor(seconds: 0.2)
        c: sleepFor(seconds: 0.8)
        d: sleepFor(seconds: 0.1)
      }
    |}
    it "doesn't terminate long-running field execution" do
      expected_data = {
        "a"=>0.2,
        "b"=>0.2,
        "c"=>0.8,
        "d"=>nil,
      }

      expected_errors = [
        {
          "message"=>"Timeout on Query.sleepFor",
          "locations"=>[{"line"=>6, "column"=>9}],
          "path"=>["d"]
        },
      ]

      assert_equal expected_data, result["data"]
      assert_equal expected_errors, result["errors"]
    end
  end

  describe "with a custom block" do
    let(:timeout_middleware) {
      GraphQL::Schema::TimeoutMiddleware.new(max_seconds: max_seconds) do |err, query|
        raise("Query timed out after 2s: #{query.operations.count} on #{query.context.ast_node.alias}")
      end
    }
    let(:query_string) {%|
      {
        a: sleepFor(seconds: 0.4)
        b: sleepFor(seconds: 0.4)
        c: sleepFor(seconds: 0.4)
        d: sleepFor(seconds: 0.4)
        e: sleepFor(seconds: 0.4)
      }
    |}

    it "calls the block" do
      err = assert_raises(RuntimeError) { result }
      assert_equal "Query timed out after 2s: 1 on d", err.message
    end
  end
end
