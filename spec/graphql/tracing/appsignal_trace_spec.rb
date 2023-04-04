# frozen_string_literal: true

require "spec_helper"

module Appsignal
  module_function

  def instrument(key, &block)
    instrumented << key
    yield
  end

  def instrumented
    @instrumented ||= []
  end
end

describe GraphQL::Tracing::AppsignalTrace do
  module AppsignalTraceTest
    class Thing < GraphQL::Schema::Object
      field :str, String

      def str; "blah"; end
    end

    class Named < GraphQL::Schema::Union
      possible_types Thing
      def self.resolve_type(obj, ctx)
        Thing
      end
    end

    class Query < GraphQL::Schema::Object
      include GraphQL::Types::Relay::HasNodeField

      field :int, Integer, null: false

      def int
        1
      end

      field :thing, Thing
      def thing; :thing; end

      field :named, Named, resolver_method: :thing
    end

    class TestSchema < GraphQL::Schema
      query(Query)
      trace_with(GraphQL::Tracing::AppsignalTrace)
    end
  end

  before do
    Appsignal.instrumented.clear
  end

  it "traces events" do
    _res = AppsignalTraceTest::TestSchema.execute("{ int thing { str } named { ... on Thing { str } } }")
    expected_trace = [
      "execute.graphql",
      "analyze.graphql",
      "lex.graphql",
      "parse.graphql",
      "validate.graphql",
      "analyze.graphql",
      "execute.graphql",
      "Query.authorized.graphql",
      "Query.thing.graphql",
      "Thing.authorized.graphql",
      "Query.named.graphql",
      "Named.resolve_type.graphql",
      "Thing.authorized.graphql",
      "execute.graphql",
    ]
    assert_equal expected_trace, Appsignal.instrumented
  end
end
