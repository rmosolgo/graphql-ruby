# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::SentryTrace do
  module SentryTraceTest
    class Thing < GraphQL::Schema::Object
      field :str, String
      def str; "blah"; end
    end

    class Query < GraphQL::Schema::Object
      field :int, Integer, null: false

      def int
        1
      end

      field :thing, Thing
      def thing; :thing; end
    end

    class SchemaWithoutTransactionName < GraphQL::Schema
      query(Query)

      module OtherTrace
        def execute_query(query:)
          query.context[:other_trace_ran] = true
          super
        end
      end
      trace_with OtherTrace
      trace_with GraphQL::Tracing::SentryTrace
    end

    class SchemaWithTransactionName < GraphQL::Schema
      query(Query)
      trace_with(GraphQL::Tracing::SentryTrace, set_transaction_name: true)
    end
  end

  before do
    Sentry.clear_all
  end

  def exec_query(query_str, context: {}, schema: SentryTraceTest::SchemaWithoutTransactionName)
    if TESTING_BATCHING
      schema.execute_batching(query_str, context: context)
    else
      schema.execute(query_str, context: context)
    end
  end

  it "works with other trace modules" do
    res = exec_query("{ int }")
    assert res.context[:other_trace_ran]
  end

  it "handles cases when Sentry has no current span" do
    Sentry.use_nil_span = true
    assert exec_query("{ int }")
  ensure
    Sentry.use_nil_span = false
  end

  describe "When Sentry is not configured" do
    it "does not initialize any spans" do
      Sentry.stub(:initialized?, false) do
        exec_query("{ int thing { str } }")
        assert_equal [], Sentry::SPAN_DATA
        assert_equal [], Sentry::SPAN_DESCRIPTIONS
        assert_equal [], Sentry::SPAN_OPS
      end
    end
  end

  describe "When Sentry.with_child_span / start_child returns nil" do
    it "does not initialize any spans" do
      Sentry.stub(:with_child_span, nil) do
        Sentry::DummySpan.stub(:start_child, nil) do
          exec_query("{ int thing { str } }")
          assert_equal [], Sentry::SPAN_DATA
          assert_equal [], Sentry::SPAN_DESCRIPTIONS
          assert_equal [], Sentry::SPAN_OPS
        end
      end
    end
  end

  it "sets the expected spans" do
    exec_query("{ int thing { str } }")
    expected_span_ops = [
      "graphql.execute",
      "graphql.analyze",
      (USING_C_PARSER ? "graphql.lex" : nil),
      "graphql.parse",
      "graphql.validate",
      "graphql.authorized.Query",
      "graphql.Query.thing",
      "graphql.authorized.Thing",
    ].compact

    assert_equal expected_span_ops, Sentry::SPAN_OPS
  end

  it "sets span descriptions for an anonymous query" do
    exec_query("{ int }")
    assert_equal ["query"], Sentry::SPAN_DESCRIPTIONS
  end

  it "sets span data for an anonymous query" do
    exec_query("{ int }")
    expected_span_data = [
      ["graphql.document", "{ int }"],
      ["graphql.operation.type", "query"]
    ].compact

    assert_equal expected_span_data.sort, Sentry::SPAN_DATA.sort
  end

  it "sets span descriptions for a named query" do
    exec_query("query Ab { int }")
    assert_equal ["query Ab"], Sentry::SPAN_DESCRIPTIONS
  end

  it "sets span data for a named query" do
    exec_query("query Ab { int }")
    expected_span_data = [
      ["graphql.document", "query Ab { int }"],
      ["graphql.operation.name", "Ab"],
      ["graphql.operation.type", "query"]
    ].compact

    assert_equal expected_span_data.sort, Sentry::SPAN_DATA.sort
  end

  it "can leave the transaction name in place" do
    exec_query "query X { int }"
    assert_equal [], Sentry::TRANSACTION_NAMES
  end

  it "can override the transaction name" do
    exec_query "query X { int }", schema: SentryTraceTest::SchemaWithTransactionName
    assert_equal ["GraphQL/query.X"], Sentry::TRANSACTION_NAMES
  end

  it "can override the transaction name per query" do
    # Override with `false`
    exec_query("{ int }", context: { set_sentry_transaction_name: false }, schema: SentryTraceTest::SchemaWithTransactionName)
    assert_equal [], Sentry::TRANSACTION_NAMES
    # Override with `true`
    exec_query "{ int }", context: { set_sentry_transaction_name: true }
    assert_equal ["GraphQL/query.anonymous"], Sentry::TRANSACTION_NAMES
  end

  it "falls back to a :tracing_fallback_transaction_name when provided" do
    exec_query("{ int }", context: { tracing_fallback_transaction_name: "Abcd" }, schema: SentryTraceTest::SchemaWithTransactionName)
    assert_equal ["GraphQL/query.Abcd"], Sentry::TRANSACTION_NAMES
  end

  it "does not use the :tracing_fallback_transaction_name if an operation name is present" do
    exec_query(
      "query Ab { int }",
      context: { tracing_fallback_transaction_name: "Cd" },
      schema: SentryTraceTest::SchemaWithTransactionName
    )
    assert_equal ["GraphQL/query.Ab"], Sentry::TRANSACTION_NAMES
  end

  it "does not require a :tracing_fallback_transaction_name even if an operation name is not present" do
    exec_query("{ int }", schema: SentryTraceTest::SchemaWithTransactionName)
    assert_equal ["GraphQL/query.anonymous"], Sentry::TRANSACTION_NAMES
  end
end
