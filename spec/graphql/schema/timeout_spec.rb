# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Timeout do
  module OtherTrace
    def execute_field(query:, **opts)
      query.context[:other_trace_worked] = true
      super
    end
  end

  class CustomTimeout < GraphQL::Schema::Timeout
    def handle_timeout(error, query)
      if query.context[:disable_timeout]
        disable_timeout(query)
      end
      super
    end
  end

  let(:max_seconds) { 0.2 }
  let(:timeout_class) { CustomTimeout }
  let(:timeout_schema) {
    nested_sleep_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "NestedSleep"

      field :seconds, Float, resolve_legacy_instance_method: true

      def seconds
        object
      end

      field :nested_sleep, self, resolve_legacy_instance_method: true do
        argument :seconds, Float
      end

      def nested_sleep(seconds:)
        sleep(seconds)
        seconds
      end
    end

    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"

      field :sleep_for, Float, resolve_legacy_instance_method: true do
        argument :seconds, Float
        argument :disable_timeout, "Boolean", default_value: false
      end

      def sleep_for(seconds:, disable_timeout:)
        if disable_timeout
          context[:disable_timeout] = true
        end
        sleep(seconds)
        seconds
      end

      field :nested_sleep, nested_sleep_type, resolve_legacy_instance_method: true do
        argument :seconds, Float
      end

      def nested_sleep(seconds:)
        sleep(seconds)
        seconds
      end
    end

    schema = Class.new(GraphQL::Schema) do
      query query_type
      trace_with OtherTrace
    end
    schema.use timeout_class, max_seconds: max_seconds
    schema
  }
  let(:query_context) { {} }
  let(:result) { timeout_schema.execute(query_string, context: query_context) }

  describe "timeout part-way through" do
    let(:query_string) {%|
      {
        a: sleepFor(seconds: 0.08)
        b: sleepFor(seconds: 0.08)
        c: sleepFor(seconds: 0.08)
        d: sleepFor(seconds: 0.08)
        e: sleepFor(seconds: 0.08)
      }
    |}
    it "returns a partial response and error messages" do
      expected_data = {
        "a"=>0.08,
        "b"=>0.08,
        "c"=>0.08,
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
      assert_graphql_equal expected_data, result["data"]
      assert_equal expected_errors, result["errors"]
      if TESTING_EXEC_NEXT
        refute result.context.key?(:other_trace_worked), "It terminated before calling that other trace"
      else
        assert_equal true, result.context[:other_trace_worked], "It works with other traces"
      end
    end
  end

  describe "timeout in nested fields" do
    let(:query_string) {%|
    {
      a: nestedSleep(seconds: 0.05) {
        seconds
        b: nestedSleep(seconds: 0.05) {
          seconds
          c: nestedSleep(seconds: 0.05) {
            seconds
            d: nestedSleep(seconds: 0.08) {
              seconds
              e: nestedSleep(seconds: 0.08) {
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
          "seconds" => 0.05,
          "b" => {
            "seconds" => 0.05,
            "c" => {
              "seconds"=>0.05,
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

      assert_graphql_equal expected_data, result["data"]
      assert_equal expected_errors, result["errors"]
    end
  end

  describe "long-running fields" do
    let(:query_string) {%|
      {
        a: sleepFor(seconds: 0.04)
        b: sleepFor(seconds: 0.04)
        c: sleepFor(seconds: 0.16)
        d: sleepFor(seconds: 0.02)
      }
    |}
    it "doesn't terminate long-running field execution" do
      expected_data = {
        "a"=>0.04,
        "b"=>0.04,
        "c"=>0.16,
        "d"=>nil,
      }

      expected_errors = [
        {
          "message"=>"Timeout on Query.sleepFor",
          "locations"=>[{"line"=>6, "column"=>9}],
          "path"=>["d"]
        },
      ]

      assert_graphql_equal expected_data, result["data"]
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
        a: sleepFor(seconds: 0.08)
        b: sleepFor(seconds: 0.08)
        c: sleepFor(seconds: 0.08)
        d: sleepFor(seconds: 0.08)
        e: sleepFor(seconds: 0.08)
      }
    |}

    it "calls the block" do
      err = assert_raises(RuntimeError) { result }
      assert_equal exec_next_error_message("Query.sleepFor", "Query timed out after 2s: Timeout on Query.sleepFor"), err.message
    end
  end

  describe "query-specific timeout duration" do
    let(:timeout_class) {
      Class.new(GraphQL::Schema::Timeout) do
        def max_seconds(query)
          query.context[:max_seconds]
        end

        def handle_timeout(err, query)
          max_s = query.context[:max_seconds]
          raise(GraphQL::ExecutionError, "Query timed out after #{max_s}s: #{err.message}")
        end
      end
    }

    let(:query_context) {
      { max_seconds: 0.38 }
    }

    let(:query_string) {%|
      {
        a: sleepFor(seconds: 0.1)
        b: sleepFor(seconds: 0.1)
        c: sleepFor(seconds: 0.1)
        d: sleepFor(seconds: 0.1)
        e: sleepFor(seconds: 0.1)
      }
    |}

    it "uses the configured #max_seconds(query) method" do
      expected_data = {"a"=>0.1, "b"=>0.1, "c"=>0.1, "d"=>0.1, "e"=>nil}
      assert_equal(expected_data, result["data"])
      errors = result["errors"]
      expected_message = "Query timed out after 0.38s: Timeout on Query.sleepFor"
      assert_equal [expected_message], errors.map { |e| e["message"] }
    end

    describe "when max_seconds returns false" do
      let(:query_context) { {max_seconds: false} }
      it "doesn't apply any timeout" do
        expected_data = {"a"=>0.1, "b"=>0.1, "c"=>0.1, "d"=>0.1, "e"=>0.1}
        assert_equal(expected_data, result["data"])
      end
    end
  end


  describe "disabling the timeout" do
    let(:query_string) {%|
    query GetTimeouts($disable: Boolean) {
      a: sleepFor(seconds: 0.08)
      b: sleepFor(seconds: 0.08)
      c: sleepFor(seconds: 0.08, disableTimeout: $disable)
      d: sleepFor(seconds: 0.08)
      e: sleepFor(seconds: 0.08)
    }
  |}

    it "can be disabled" do
      expected_data = {
        "a"=>0.08,
        "b"=>0.08,
        "c"=>0.08,
        "d"=>nil,
        "e"=>nil,
      }

      assert_graphql_equal expected_data, result["data"]

      disabled_timeout_result = timeout_schema.execute(query_string, context: query_context, variables: { disable: true })
      expected_disabled_data = {
        "a"=>0.08,
        "b"=>0.08,
        "c"=>0.08,
        "d"=>0.08,
        "e"=>0.08,
      }
      assert_graphql_equal expected_disabled_data, disabled_timeout_result["data"]
    end
  end
end
