# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Multiplex do
  def multiplex(*a, **kw)
    LazyHelpers::LazySchema.multiplex(*a, **kw)
  end

  let(:q1) { <<-GRAPHQL
    query Q1 {
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
    query Q2 {
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
    query Q3 {
      listSum(values: [1,2]) {
        nestedSum(value: 3) {
          value
        }
      }
    }
    GRAPHQL
  }

  let(:queries) { [{query: q1}, {query: q2}, {query: q3}] }

  describe "multiple queries in the same lazy context" do
    it "runs multiple queries in the same lazy context" do
      expected_data = [
        {"data"=>{"nestedSum"=>{"value"=>14, "nestedSum"=>{"value"=>46}}}},
        {"data"=>{"nestedSum"=>{"value"=>14, "nestedSum"=>{"value"=>46}}}},
        {"data"=>{"listSum"=>[{"nestedSum"=>{"value"=>14}}, {"nestedSum"=>{"value"=>14}}]}},
      ]

      res = multiplex(queries)
      assert_equal expected_data, res
    end

    it "returns responses in the same order as their respective requests" do
      queries = 2000.times.map do |index|
        case index % 3
        when 0
          {query: q1}
        when 1
          {query: q2}
        when 2
          {query: q3}
        end
      end

      responses = multiplex(queries)

      responses.each.with_index do |response, index|
        case index % 3
        when 0
          assert_equal "Q1", response.query.operation_name
        when 1
          assert_equal "Q2", response.query.operation_name
        when 2
          assert_equal "Q3", response.query.operation_name
        end
      end
    end
  end

  describe "when some have validation errors or runtime errors" do
    let(:q1) { " { success: nullableNestedSum(value: 1) { value } }" }
    let(:q2) { " { runtimeError: nullableNestedSum(value: 13) { value } }" }
    let(:q3) { "{
      invalidNestedNull: nullableNestedSum(value: 1) {
        value
        nullableNestedSum(value: 2) {
          nestedSum(value: 13) {
            value
          }
          # This field will never get executed
          ns2: nestedSum(value: 13) {
            value
          }
        }
      }
    }" }
    let(:q4) { " { validationError: nullableNestedSum(value: true) }"}

    it "returns a mix of errors and values" do
      expected_res = [
        {
          "data"=>{"success"=>{"value"=>2}}
        },
        {
          "data"=>{"runtimeError"=>nil},
          "errors"=>[{
            "message"=>"13 is unlucky",
            "locations"=>[{"line"=>1, "column"=>4}],
            "path"=>["runtimeError"]
          }]
        },
        {
          "data"=>{"invalidNestedNull"=>{"value" => 2,"nullableNestedSum" => nil}},
          "errors"=>[{"message"=>"Cannot return null for non-nullable field LazySum.nestedSum"}],
        },
        {
          "errors" => [{
            "message"=>"Field must have selections (field 'nullableNestedSum' returns LazySum but has no selections. Did you mean 'nullableNestedSum { ... }'?)",
            "locations"=>[{"line"=>1, "column"=>4}],
            "path"=>["query", "validationError"],
            "extensions"=>{"code"=>"selectionMismatch", "nodeName"=>"field 'nullableNestedSum'", "typeName"=>"LazySum"}
          }]
        },
      ]

      res = multiplex([
        {query: q1},
        {query: q2},
        {query: q3},
        {query: q4},
      ])
      assert_equal expected_res, res.map(&:to_h)
    end
  end

  describe "context shared by a multiplex run" do
    it "is provided as context:" do
      checks = []
      multiplex(queries, context: { instrumentation_checks: checks })
      assert_equal ["before multiplex 1", "before multiplex 2", "after multiplex 2", "after multiplex 1"], checks
    end
  end

  describe "instrumenting a multiplex run" do
    it "runs query instrumentation for each query and multiplex-level instrumentation" do
      checks = []
      queries_with_context = queries.map { |q| q.merge(context: { instrumentation_checks: checks }) }
      multiplex(queries_with_context, context: { instrumentation_checks: checks })
      assert_equal [
        "before multiplex 1",
        "before multiplex 2",
        "before Q1", "before Q2", "before Q3",
        "after Q3", "after Q2", "after Q1",
        "after multiplex 2",
        "after multiplex 1",
      ], checks
    end
  end

  describe "max_complexity" do
    it "can successfully calculate complexity" do
      message = "Query has complexity of 11, which exceeds max complexity of 10"
      results = multiplex(queries, max_complexity: 10)

      results.each do |res|
        assert_equal message, res["errors"][0]["message"]
      end
    end
  end

  describe "after_query when errors are raised" do
    class InspectQueryInstrumentation
      class << self
        attr_reader :last_json
        def before_query(query)
        end

        def after_query(query)
          @last_json = query.result.to_json
        end
      end
    end

    InspectQueryType = GraphQL::ObjectType.define do
      name "Query"

      field :raiseExecutionError, types.String do
        resolve ->(object, args, ctx) {
          raise GraphQL::ExecutionError, "Whoops"
        }
      end

      field :raiseError, types.String do
        resolve ->(object, args, ctx) {
          raise GraphQL::Error, "Crash"
        }
      end

      field :raiseSyntaxError, types.String do
        resolve ->(object, args, ctx) {
          raise SyntaxError
        }
      end

      field :raiseException, types.String do
        resolve ->(object, args, ctx) {
          raise Exception
        }
      end

    end

    InspectSchema = GraphQL::Schema.define do
      query InspectQueryType
      instrument(:query, InspectQueryInstrumentation)
    end

    unhandled_err_json = '{}'

    it "can access the query results" do
      InspectSchema.execute("{ raiseExecutionError }")
      handled_err_json = '{"data":{"raiseExecutionError":null},"errors":[{"message":"Whoops","locations":[{"line":1,"column":3}],"path":["raiseExecutionError"]}]}'
      assert_equal handled_err_json, InspectQueryInstrumentation.last_json


      assert_raises(GraphQL::Error) do
        InspectSchema.execute("{ raiseError }")
      end

      assert_equal unhandled_err_json, InspectQueryInstrumentation.last_json
    end

    it "can access the query results when the error is not a StandardError" do
      assert_raises(SyntaxError) do
        InspectSchema.execute("{ raiseSyntaxError }")
      end
      assert_equal unhandled_err_json, InspectQueryInstrumentation.last_json

      assert_raises(Exception) do
        InspectSchema.execute("{ raiseException }")
      end
      assert_equal unhandled_err_json, InspectQueryInstrumentation.last_json
    end
  end
end
