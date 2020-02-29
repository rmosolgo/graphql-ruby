# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::NewRelicTracing do
  module NewRelicTest
    class Thing < GraphQL::Schema::Object
      implements GraphQL::Types::Relay::Node
    end

    class Query < GraphQL::Schema::Object
      add_field GraphQL::Types::Relay::NodeField

      field :int, Integer, null: false

      def int
        1
      end
    end

    class SchemaWithoutTransactionName < GraphQL::Schema
      query(Query)
      use(GraphQL::Tracing::NewRelicTracing)
      orphan_types(Thing)

      def self.object_from_id(_id, _ctx)
        :thing
      end

      def self.resolve_type(_type, _obj, _ctx)
        Thing
      end

      if TESTING_INTERPRETER
        use GraphQL::Execution::Interpreter
        use GraphQL::Analysis::AST
      end
    end

    class SchemaWithTransactionName < GraphQL::Schema
      query(Query)
      use(GraphQL::Tracing::NewRelicTracing, set_transaction_name: true)
      if TESTING_INTERPRETER
        use GraphQL::Execution::Interpreter
        use GraphQL::Analysis::AST
      end
    end

    class SchemaWithScalarTrace < GraphQL::Schema
      query(Query)
      use(GraphQL::Tracing::NewRelicTracing, trace_scalars: true)
      if TESTING_INTERPRETER
        use GraphQL::Execution::Interpreter
        use GraphQL::Analysis::AST
      end
    end
  end

  before do
    NewRelic.clear_all
  end

  it "works with the built-in node field, even though it doesn't have an @owner" do
    res = NewRelicTest::SchemaWithoutTransactionName.execute '{ node(id: "1") { __typename } }'
    assert_equal "Thing", res["data"]["node"]["__typename"]
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

  it "traces scalars when trace_scalars is true" do
    NewRelicTest::SchemaWithScalarTrace.execute "query X { int }"
    assert_includes NewRelic::EXECUTION_SCOPES, "GraphQL/Query/int"
  end
end
