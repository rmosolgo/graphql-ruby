# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::DataDogTrace do
  module DataDogTraceTest
    class Thing < GraphQL::Schema::Object
      field :str, String

      def str; "blah"; end
    end

    class Query < GraphQL::Schema::Object
      include GraphQL::Types::Relay::HasNodeField

      field :int, Integer, null: false

      def int
        1
      end

      field :thing, Thing
      def thing; :thing; end
    end

    module CustomQueryStringTrace
      def execute_query(query:)
        query.query_string += "\n# custom addition"
        super
      end
    end

    class TestSchema < GraphQL::Schema
      query(Query)
      trace_with(GraphQL::Tracing::DataDogTrace)
      trace_with(CustomQueryStringTrace)
    end

    class CustomTracerTestSchema < GraphQL::Schema
      module CustomDataDogTracing
        include GraphQL::Tracing::DataDogTrace
        def prepare_span(trace_key, data, span)
          span.set_tag("custom:#{trace_key}", data.keys.sort.join(","))
        end
      end
      query(Query)
      trace_with(CustomQueryStringTrace)
      trace_with(CustomDataDogTracing)
    end
  end

  before do
    Datadog.clear_all
  end

  it "falls back to a :tracing_fallback_transaction_name when provided" do
    DataDogTraceTest::TestSchema.execute("{ int }", context: { tracing_fallback_transaction_name: "Abcd" })
    assert_equal ["Abcd"], Datadog::SPAN_RESOURCE_NAMES
  end

  it "uses a modified query string, regardless of load order" do
    DataDogTraceTest::CustomTracerTestSchema.execute("query Ab { int }")
    assert_includes Datadog::SPAN_TAGS, [:query_string, "query Ab { int }\n# custom addition"]

    DataDogTraceTest::TestSchema.execute("query Ab { int }")
    assert_includes Datadog::SPAN_TAGS, [:query_string, "query Ab { int }\n# custom addition"]

  end

  it "does not use the :tracing_fallback_transaction_name if an operation name is present" do
    DataDogTraceTest::TestSchema.execute(
      "query Ab { int }",
      context: { tracing_fallback_transaction_name: "Cd" }
    )
    assert_equal ["Ab"], Datadog::SPAN_RESOURCE_NAMES
  end

  it "does not set resource if no value can be derived" do
    DataDogTraceTest::TestSchema.execute("{ int }")
    assert_equal [], Datadog::SPAN_RESOURCE_NAMES
  end

  it "sets component and operation tags" do
    DataDogTraceTest::TestSchema.execute("{ int }")
    assert_includes Datadog::SPAN_TAGS, ['component', 'graphql']
    assert_includes Datadog::SPAN_TAGS, ['operation', 'execute_multiplex']
  end

  it "sets custom tags tags" do
    DataDogTraceTest::CustomTracerTestSchema.execute("{ thing { str } }")
    expected_custom_tags = [
      ["custom:lex", "query_string"],
      ["custom:parse", "query_string"],
      ["custom:execute_multiplex", "multiplex"],
      ["custom:analyze_multiplex", "multiplex"],
      ["custom:validate", "query,validate"],
      ["custom:analyze_query", "query"],
      ["custom:execute_query", "query"],
      ["custom:authorized", "object,query,type"],
      ["custom:execute_field", "arguments,ast_node,field,object,query"],
      ["custom:authorized", "object,query,type"],
      ["custom:execute_query_lazy", "multiplex,query"],
    ]

    actual_custom_tags = Datadog::SPAN_TAGS.reject { |t| t[0] == "operation" || t[0] == "component" || t[0].is_a?(Symbol) }
    assert_equal expected_custom_tags, actual_custom_tags
  end
end
