# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::DataDogTrace do
  module DataDogTraceTest
    class Box
      def initialize(value)
        @value = value
      end
      attr_reader :value
    end

    class BaseObject < GraphQL::Schema::Object
      class BaseField < GraphQL::Schema::Field
        include(GraphQL::Execution::Next::FieldCompatibility) if TESTING_EXEC_NEXT
      end
      field_class(BaseField)
    end

    class Thing < BaseObject
      field :str, String

      def str; Box.new("blah"); end
    end

    class Query < BaseObject
      include GraphQL::Types::Relay::HasNodeField
      def self.authorized?(obj, ctx); true; end

      field :int, Integer, null: false

      def int
        1
      end

      field :thing, Thing
      def thing; :thing; end

      field :str, String
      def str
        dataloader.with(EchoSource).load("hello")
      end
    end

    class EchoSource < GraphQL::Dataloader::Source
      def fetch(strs)
        strs
      end
    end

    class TestSchema < GraphQL::Schema
      query(Query)
      use GraphQL::Dataloader
      trace_with(GraphQL::Tracing::DataDogTrace)
      lazy_resolve(Box, :value)
      use GraphQL::Execution::Next if TESTING_EXEC_NEXT
    end

    class CustomTracerTestSchema < GraphQL::Schema
      module CustomDataDogTracing
        include GraphQL::Tracing::DataDogTrace
        def prepare_span(trace_key, object, span)
          span.set_tag("custom:#{trace_key}", object.class.name)
        end
      end
      query(Query)
      trace_with(CustomDataDogTracing)
      lazy_resolve(Box, :value)
      use GraphQL::Execution::Next if TESTING_EXEC_NEXT
    end
  end

  before do
    Datadog.clear_all
  end

  def exec_query(query_str, context: {}, schema: DataDogTraceTest::TestSchema)
    if TESTING_EXEC_NEXT
      schema.execute_next(query_str, context: context)
    else
      schema.execute(query_str, context: context)
    end
  end

  it "falls back to a :tracing_fallback_transaction_name when provided" do
    exec_query("{ int }", context: { tracing_fallback_transaction_name: "Abcd" })
    assert_equal ["Abcd"], Datadog::SPAN_RESOURCE_NAMES
  end

  it "does not use the :tracing_fallback_transaction_name if an operation name is present" do
    exec_query(
      "query Ab { int }",
      context: { tracing_fallback_transaction_name: "Cd" }
    )
    assert_equal ["Ab"], Datadog::SPAN_RESOURCE_NAMES
  end

  it "does not set resource if no value can be derived" do
    exec_query("{ int }")
    assert_equal [], Datadog::SPAN_RESOURCE_NAMES
  end

  it "sets component and operation tags" do
    exec_query("{ int }")
    assert_includes Datadog::SPAN_TAGS, ['component', 'graphql']
    assert_includes Datadog::SPAN_TAGS, ['operation', 'execute']
  end

  it "works with dataloader" do
    exec_query("{ str }")
    expected_keys = [
      "execute.graphql",
      (USING_C_PARSER ? "lex.graphql" : nil),
      "parse.graphql",
      "analyze.graphql",
      "validate.graphql",
      "Query.authorized.graphql",
      "DataDogTraceTest_EchoSource.fetch.graphql"
    ].compact
    assert_equal expected_keys, Datadog::TRACE_KEYS
  end

  it "sets custom tags" do
    exec_query("{ thing { str } }", schema: DataDogTraceTest::CustomTracerTestSchema)
    expected_custom_tags = [
      (USING_C_PARSER ? ["custom:lex", "String"] : nil),
      ["custom:parse", "String"],
      ["selected_operation_name", nil],
      ["selected_operation_type", "query"],
      ["query_string", "{ thing { str } }"],
      ["custom:execute", "GraphQL::Execution::Multiplex"],
      ["custom:validate", "GraphQL::Query"],
    ].compact

    actual_custom_tags = Datadog::SPAN_TAGS.reject { |t| t[0] == "operation" || t[0] == "component" || t[0].is_a?(Symbol) }
    assert_equal expected_custom_tags, actual_custom_tags
  end
end
