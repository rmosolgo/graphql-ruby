# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::ScoutTrace do
  module ScoutApmTraceTest
    class Query < GraphQL::Schema::Object
      include GraphQL::Types::Relay::HasNodeField

      field :int, Integer, null: false

      def int
        1
      end
    end

    class ScoutSchemaBase < GraphQL::Schema
      query(Query)
    end

    class SchemaWithoutTransactionName < ScoutSchemaBase
      trace_with GraphQL::Tracing::ScoutTrace
    end

    class SchemaWithTransactionName < ScoutSchemaBase
      trace_with GraphQL::Tracing::ScoutTrace, set_transaction_name: true, trace_authorized: false, trace_scalars: true
    end
  end

  before do
    ScoutApm.clear_all
  end

  it "can leave the transaction name in place" do
    ScoutApmTraceTest::SchemaWithoutTransactionName.execute "query X { int }"
    assert_equal [], ScoutApm::TRANSACTION_NAMES
    expected_events = [
      "execute.graphql",
      "analyze.graphql",
      (USING_C_PARSER ? "lex.graphql" : nil),
      "parse.graphql",
      "validate.graphql",
      "Query.authorized.graphql"
    ].compact
    assert_equal expected_events, ScoutApm::EVENTS
  end

  it "can override the transaction name, skip authorized, and trace scalars" do
    ScoutApmTraceTest::SchemaWithTransactionName.execute "query X { int }"
    assert_equal ["GraphQL/query.X"], ScoutApm::TRANSACTION_NAMES
    expected_events = [
      (USING_C_PARSER ? "lex.graphql" : nil),
      "parse.graphql",
      "execute.graphql",
      "analyze.graphql",
      "validate.graphql",
      "Query.int.graphql"
    ].compact
    assert_equal expected_events, ScoutApm::EVENTS
  end

  it "can override the transaction name per query" do
    # Override with `false`
    ScoutApmTraceTest::SchemaWithTransactionName.execute "{ int }", context: { set_scout_transaction_name: false }
    assert_equal [], ScoutApm::TRANSACTION_NAMES
    # Override with `true`
    ScoutApmTraceTest::SchemaWithoutTransactionName.execute "{ int }", context: { set_scout_transaction_name: true }
    assert_equal ["GraphQL/query.anonymous"], ScoutApm::TRANSACTION_NAMES
  end
end
