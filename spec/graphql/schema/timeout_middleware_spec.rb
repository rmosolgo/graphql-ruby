require "spec_helper"

describe GraphQL::Schema::TimeoutMiddleware do
  let(:max_seconds) { 2 }
  let(:timeout_schema) {

    sleep_for_seconds_resolve = -> (obj, args, ctx) {
      sleep(args[:seconds])
      args[:seconds]
    }

    nested_sleep_type = GraphQL::ObjectType.define do
      name "NestedSleep"
      field :seconds, types.Float do
        resolve -> (obj, args, ctx) { obj }
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

    schema = GraphQL::Schema.new(query: query_type)
    schema.middleware << GraphQL::Schema::TimeoutMiddleware.new(max_seconds: 2)
    schema
  }

  let(:result) { timeout_schema.execute(query_string) }

  describe "timeout part-way through" do
    let(:query_string) {%|
      {
        a: sleepFor(seconds: 0.7)
        b: sleepFor(seconds: 0.7)
        c: sleepFor(seconds: 0.7)
        d: sleepFor(seconds: 0.7)
        e: sleepFor(seconds: 0.7)
      }
    |}
    it "returns a partial response and error messages" do
      expected_data = {
        "a"=>0.7,
        "b"=>0.7,
        "c"=>0.7,
        "d"=>nil,
        "e"=>nil,
      }

      expected_errors =  [
        {
          "message"=>"Timeout on Query.sleepFor",
          "locations"=>[{"line"=>6, "column"=>9}]
        },
        {
          "message"=>"Timeout on Query.sleepFor",
          "locations"=>[{"line"=>7, "column"=>9}]
        },
      ]
      assert_equal expected_data, result["data"]
      assert_equal expected_errors, result["errors"]
    end
  end

  describe "timeout in nested fields" do
    let(:query_string) {%|
    {
      a: nestedSleep(seconds: 1) {
        seconds
        b: nestedSleep(seconds: 0.4) {
          seconds
          c: nestedSleep(seconds: 0.4) {
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
          "seconds" => 1.0,
          "b" => {
            "seconds" => 0.4,
            "c" => {
              "seconds"=>0.4,
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
          "locations"=>[{"line"=>10, "column"=>15}]
        },
        {
          "message"=>"Timeout on NestedSleep.nestedSleep",
          "locations"=>[{"line"=>11, "column"=>15}]
        },
      ]

      assert_equal expected_data, result["data"]
      assert_equal expected_errors, result["errors"]
    end
  end

  describe "long-running fields" do
    let(:query_string) {%|
      {
        a: sleepFor(seconds: 0.7)
        b: sleepFor(seconds: 0.7)
        c: sleepFor(seconds: 1.5)
        d: sleepFor(seconds: 0.1)
      }
    |}
    it "doesn't terminate long-running field execution" do
      expected_data = {
        "a"=>0.7,
        "b"=>0.7,
        "c"=>1.5,
        "d"=>nil,
      }

      expected_errors = [
        {
          "message"=>"Timeout on Query.sleepFor",
          "locations"=>[{"line"=>6, "column"=>9}]
        },
      ]

      assert_equal expected_data, result["data"]
      assert_equal expected_errors, result["errors"]
    end
  end
end
