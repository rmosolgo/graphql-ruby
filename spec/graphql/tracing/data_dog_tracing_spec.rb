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

  it "does not require a :tracing_fallback_transaction_name even if an operation name is not present" do
    DataDogTest::TestSchema.execute("{ int }")
    assert_equal [nil], Datadog::SPAN_RESOURCE_NAMES
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

    actual_custom_tags = Datadog::SPAN_TAGS.reject { |t| t[0] == "operation" || t[0] == "component" || t[0].is_a?(Symbol) }
    assert_equal expected_custom_tags, actual_custom_tags
  end
end
