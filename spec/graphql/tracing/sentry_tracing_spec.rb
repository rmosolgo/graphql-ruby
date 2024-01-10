# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::SentryTracing do
  class SentryTracingTestSchema < GraphQL::Schema
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

    query Query

    use GraphQL::Tracing::SentryTracing
  end

  before do
    Sentry.clear_all
  end

  describe 'When Sentry is not configured' do
    it 'does not initialize any spans' do
      Sentry.stub(:initialized?, false) do
        SentryTracingTestSchema.execute("{ int thing { str } }")
        assert_equal [], Sentry::SPAN_DATA
        assert_equal [], Sentry::SPAN_DESCRIPTIONS
        assert_equal [], Sentry::SPAN_OPS
      end
    end
  end

  it "sets the expected spans" do
    SentryTracingTestSchema.execute("{ int thing { str } }")
    expected_span_ops = [
      "graphql.execute_multiplex",
      "graphql.analyze_multiplex",
      (USING_C_PARSER ? "graphql.lex" : nil),
      "graphql.parse",
      "graphql.validate",
      "graphql.analyze",
      "graphql.execute",
      "graphql.authorized.Query",
      "graphql.Query.thing",
      "graphql.authorized.Thing",
      "graphql.execute"
    ].compact

    assert_equal expected_span_ops, Sentry::SPAN_OPS
  end

  it "sets span descriptions for an anonymous query" do
    debugger
    SentryTracingTestSchema.execute("{ int }")

    assert_equal ['query'], Sentry::SPAN_DESCRIPTIONS
  end

  it "sets span data for an anonymous query" do
    SentryTracingTestSchema.execute("{ int }")
    expected_span_data = [
      ["graphql.document", "{ int }"],
      ["graphql.operation.type", "query"]
    ].compact

    assert_equal expected_span_data.sort, Sentry::SPAN_DATA.sort
  end

  it "sets span descriptions for a named query" do
    SentryTracingTestSchema.execute("query Ab { int }")

    assert_equal ['query Ab'], Sentry::SPAN_DESCRIPTIONS
  end

  it "sets span data for a named query" do
    SentryTracingTestSchema.execute("query Ab { int }")
    expected_span_data = [
      ["graphql.document", "query Ab { int }"],
      ["graphql.operation.name", "Ab"],
      ["graphql.operation.type", "query"]
    ].compact

    assert_equal expected_span_data.sort, Sentry::SPAN_DATA.sort
  end
end
