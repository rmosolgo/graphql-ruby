# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::SentryTrace do
  class SentryTraceTestSchema < GraphQL::Schema
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

    query(Query)

    trace_with GraphQL::Tracing::SentryTrace
  end

  before do
    Sentry.clear_all
  end

  describe 'When Sentry is not configured' do
    it 'does not initialize any spans' do
      Sentry.stub(:initialized?, false) do
        SentryTraceTestSchema.execute("{ int thing { str } }")
        assert_equal [], Sentry::SPAN_OPS
        assert_equal [], Sentry::SPAN_DATA
      end
    end
  end

  it "sets the expected spans" do
    SentryTraceTestSchema.execute("{ int thing { str } }")
    expected_span_ops = [
      "graphql.execute",
      "graphql.analyze",
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

  it "sets span data for the query" do
    SentryTraceTestSchema.execute("query Ab { thing { str } }")
    expected_span_data = [
      [:operation_name, "Ab"],
      [:operation_type, "query"],
      [:query_string, "query Ab { thing { str } }"]
    ].compact

    assert_equal expected_span_data.sort, Sentry::SPAN_DATA.sort
  end
end
