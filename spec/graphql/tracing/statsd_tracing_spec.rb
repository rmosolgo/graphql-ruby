# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::StatsdTracing do
  module MockStatsd
    class << self
      def time(key)
        self.timings << key
        yield
      end

      attr_reader :timings

      def clear
        @timings = []
      end
    end
  end

  class StatsdTestSchema < GraphQL::Schema
    class Thing < GraphQL::Schema::Object
      field :str, String, resolve_static: true
      def self.str(context); "blah"; end

      def str; self.class.str(context); end
    end

    class Query < GraphQL::Schema::Object
      field :int, Integer, null: false, resolve_static: true

      def self.int(context)
        1
      end

      def int
        self.class.int(context)
      end

      field :thing, Thing, resolve_static: true
      def self.thing(context); :thing; end

      def thing; self.class.thing(context); end
    end

    query(Query)

    use GraphQL::Tracing::StatsdTracing, statsd: MockStatsd, legacy_tracing: true
  end

  before do
    MockStatsd.clear
  end

  it "gathers timings" do
    StatsdTestSchema.execute("query X { int thing { str } }")
    expected_timings = [
      "graphql.execute_multiplex",
      "graphql.analyze_multiplex",
      (USING_C_PARSER ? "graphql.lex" : nil),
      "graphql.parse",
      "graphql.validate",
      "graphql.analyze_query",
      "graphql.execute_query",
      *(TESTING_EXEC_NEXT ? [] : [
        "graphql.authorized.Query",
        "graphql.Query.thing",
        "graphql.authorized.Thing",
      ]),
      "graphql.execute_query_lazy"
    ].compact
    assert_equal expected_timings, MockStatsd.timings
  end
end
