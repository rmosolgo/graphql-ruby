# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::DataDogTracing do
  module DataDogTest
    class Query < GraphQL::Schema::Object
      include GraphQL::Types::Relay::HasNodeField

      field :int, Integer, null: false

      def int
        1
      end
    end

    class TestSchema < GraphQL::Schema
      query(Query)
      use(GraphQL::Tracing::DataDogTracing)
    end

    class CustomTracerTestSchema < GraphQL::Schema
      class CustomDataDogTracing < GraphQL::Tracing::DataDogTracing
        def prepare_span(trace_key, data, span)
          span.set_tag("custom:#{trace_key}", data.keys.join(","))
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

  it "sets component and operation tags" do
    DataDogTest::TestSchema.execute("{ int }")

    assert_includes Datadog::SPAN_TAGS, ['component', 'graphql']
    assert_includes Datadog::SPAN_TAGS, ['operation', 'execute_multiplex']
  end

  describe '`graphql.source` tag' do
    it do
      DataDogTest::TestSchema.execute("{ int }")

      assert_includes Datadog::SPAN_TAGS, ['graphql.source', '{ int }']
    end
  end

  describe '`graphql.operation.name` tag' do
    it do
      DataDogTest::TestSchema.execute("query Bailey { int }")

      assert_includes Datadog::SPAN_TAGS, ['graphql.operation.name', 'Bailey']
    end

    it do
      DataDogTest::TestSchema.execute("{ int }")

      tags = Datadog::SPAN_TAGS.select do |t|
        t[0] == 'graphql.operation.name'
      end

      assert_empty tags
    end
  end

  describe '`graphql.operation.type` tag' do
    it do
      DataDogTest::TestSchema.execute("{ int }")

      assert_includes Datadog::SPAN_TAGS, ['graphql.operation.type', 'query']
    end
  end

  it "sets custom tags tags" do
    DataDogTest::CustomTracerTestSchema.execute("{ int }")
    expected_custom_tags = [
      ["custom:lex", "query_string"],
      ["custom:parse", "query_string"],
      ["custom:execute_multiplex", "multiplex"],
      ["custom:analyze_multiplex", "multiplex"],
      ["custom:validate", "validate,query"],
      ["custom:analyze_query", "query"],
      ["custom:execute_query", "query"],
      ["custom:authorized", "context,type,object,path"],
      ["custom:execute_query_lazy", "multiplex,query"],
    ]

    actual_custom_tags = Datadog::SPAN_TAGS.reject do |t|
      t[0] == "operation" ||
        t[0] == "component" ||
        t[0] =~ /^graphql./ ||
        t[0].is_a?(Symbol)
    end

    assert_equal expected_custom_tags, actual_custom_tags
  end
end
