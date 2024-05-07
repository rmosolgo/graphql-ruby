# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::DataDogTracing do
  module DataDogTest
    class Thing < GraphQL::Schema::Object
      field :str, String

      def str
        "blah"
      end
    end

    class Query < GraphQL::Schema::Object
      include GraphQL::Types::Relay::HasNodeField

      field :int, Integer, null: false

      def int
        1
      end

      field :thing, Thing

      def thing
        :thing
      end
    end

    class TestSchema < GraphQL::Schema
      query(Query)
      use(GraphQL::Tracing::DataDogTracing)
    end

    class CustomTracerTestSchema < GraphQL::Schema
      class CustomDataDogTracing < GraphQL::Tracing::DataDogTracing
        def prepare_span(trace_key, data, span)
          span.set_tag("custom:#{trace_key}", data.keys.sort.join(","))
        end
      end
      query(Query)
      use(CustomDataDogTracing)
    end
  end

  before do
    Datadog.clear_all
  end

  it "falls back to a :tracing_fallback_transaction_name when provided" do
    DataDogTest::TestSchema.execute("{ int }", context: { tracing_fallback_transaction_name: "Abcd" })
    assert_equal ["Abcd"], Datadog::SPAN_RESOURCE_NAMES
  end

  it "does not use the :tracing_fallback_transaction_name if an operation name is present" do
    DataDogTest::TestSchema.execute(
      "query Ab { int }",
      context: { tracing_fallback_transaction_name: "Cd" }
    )
    assert_equal ["Ab"], Datadog::SPAN_RESOURCE_NAMES
  end

  it "does not set resource if no value can be derived" do
    DataDogTest::TestSchema.execute("{ int }")
    assert_equal [], Datadog::SPAN_RESOURCE_NAMES
  end

  it "sets source and operation.type tags" do
    DataDogTest::TestSchema.execute("{ int }")
    # parse, validate, execute_query
    assert_includes Datadog::SPAN_TAGS, ['graphql.source', '{ int }']
    # execute_multiplex
    assert_includes Datadog::SPAN_TAGS, ['graphql.source', 'Multiplex[{ int }]']
    # execute_query
    assert_includes Datadog::SPAN_TAGS, ['graphql.operation.type', 'query']
  end

  it "sets custom tags tags" do
    DataDogTest::CustomTracerTestSchema.execute("{ thing { str } }")
    expected_custom_tags = [
      (USING_C_PARSER ? ["custom:lex", "query_string"] : nil),
      ["custom:parse", "query_string"],
      ["custom:execute_multiplex", "multiplex"],
      ["custom:analyze_multiplex", "multiplex"],
      ["custom:validate", "query,validate"],
      ["custom:analyze", "query"],
      ["custom:execute", "query"],
      ["custom:authorized", "context,object,path,type"],
      ["custom:resolve", "arguments,ast_node,field,object,owner,path,query"],
      ["custom:authorized", "context,object,path,type"],
      ["custom:execute_lazy", "multiplex,query"],
    ].compact

    actual_custom_tags = Datadog::SPAN_TAGS.reject { |t| /^graphql\./.match?(t[0])  || t[0].is_a?(Symbol) }
    assert_equal expected_custom_tags, actual_custom_tags
  end

  it "sets resource name correctly with named queries in multiplex" do
    queries = [
      { query: 'query Query1 { int }' },
      { query: 'query Query2 { thing { str } }' },
    ]
    DataDogTest::TestSchema.multiplex(queries)
    assert_equal ["Query1, Query2"], Datadog::SPAN_RESOURCE_NAMES
  end

  it "sets resource name correctly with 1 named and 1 unnamed query in multiplex" do
    queries = [
      { query: 'query { int }' },
      { query: 'query Query2 { thing { str } }' },
    ]
    DataDogTest::TestSchema.multiplex(queries)
    assert_equal ["Query2"], Datadog::SPAN_RESOURCE_NAMES
  end

  it "does not sets resource name with unnamed queries in multiplex" do
    queries = [
      { query: 'query { int }' },
      { query: 'query { thing { str } }' },
    ]
    DataDogTest::TestSchema.multiplex(queries)
    assert_equal [], Datadog::SPAN_RESOURCE_NAMES
  end
end
