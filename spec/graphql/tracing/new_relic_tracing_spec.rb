# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::NewRelicTracing do
  module NewRelicTest
    class Query < GraphQL::Schema::Object
      field :int, Integer, null: false

      def int
        1
      end
    end

    class SchemaWithoutTransactionName < GraphQL::Schema
      query(Query)
      use(GraphQL::Tracing::NewRelicTracing)
    end

    class SchemaWithTransactionName < GraphQL::Schema
      query(Query)
      use(GraphQL::Tracing::NewRelicTracing, set_transaction_name: true)
    end
  end

  before do
    NewRelic.clear_all
  end

  it "can leave the transaction name in place" do
    NewRelicTest::SchemaWithoutTransactionName.execute "query X { int }"
    assert_equal [], NewRelic::TRANSACTION_NAMES
  end

  it "can override the transaction name" do
    NewRelicTest::SchemaWithTransactionName.execute "query X { int }"
    assert_equal ["GraphQL/query.X"], NewRelic::TRANSACTION_NAMES
  end

  it "can override the transaction name per query" do
    # Override with `false`
    NewRelicTest::SchemaWithTransactionName.execute "{ int }", context: { set_new_relic_transaction_name: false }
    assert_equal [], NewRelic::TRANSACTION_NAMES
    # Override with `true`
    NewRelicTest::SchemaWithoutTransactionName.execute "{ int }", context: { set_new_relic_transaction_name: true }
    assert_equal ["GraphQL/query.anonymous"], NewRelic::TRANSACTION_NAMES
  end
end
