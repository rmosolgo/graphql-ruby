# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Timeout do
  let(:max_seconds) { 1 }
  let(:timeout_class) { GraphQL::Schema::Timeout }
  let(:timeout_schema) {
    nested_sleep_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "NestedSleep"

      field :seconds, Float, null: true

      def seconds
        object
      end

      field :nested_sleep, GraphQL::Schema::LateBoundType.new(graphql_name), null: true do
        argument :seconds, Float, required: true
      end

      def nested_sleep(seconds:)
        sleep(seconds)
        seconds
      end
    end

    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"

      field :sleep_for, Float, null: true do
        argument :seconds, Float, required: true
      end

      def sleep_for(seconds:)
        sleep(seconds)
        seconds
      end

      field :nested_sleep, nested_sleep_type, null: true do
        argument :seconds, Float, required: true
      end

      def nested_sleep(seconds:)
        sleep(seconds)
        seconds
      end
    end

    schema = Class.new(GraphQL::Schema) do
      query query_type
      if TESTING_INTERPRETER
        use GraphQL::Execution::Interpreter
      end
    end
    schema.use timeout_class, max_seconds: max_seconds
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
    let(:timeout_class) do
      Class.new(GraphQL::Schema::Timeout) do
        def handle_timeout(err, query)
          raise("Query timed out after 2s: #{err.message}")
        end
      end
    end

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
      assert_equal "Query timed out after 2s: Timeout on Query.sleepFor", err.message
    end
  end
end
