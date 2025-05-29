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

  def current
    self
  end

  def start_event
    # pass
  end

  def finish_event(name, title, body)
    instrumented << name
  end

  Transaction = self
end

describe GraphQL::Tracing::AppsignalTrace do
  class IntBox
    def initialize(value)
      @value = value
    end
    attr_reader :value
  end

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
        IntBox.new(1)
      end

      field :thing, Thing
      def thing; :thing; end

      field :named, Named, resolver_method: :thing
    end

    class TestSchema < GraphQL::Schema
      query(Query)
      trace_with(GraphQL::Tracing::AppsignalTrace)
      dataloader_lazy_setup(self)
      lazy_resolve(IntBox, :value)
    end
  end

  before do
    Appsignal.instrumented.clear
  end

  it "traces events" do
    _res = AppsignalTraceTest::TestSchema.execute("{ int thing { str } named { ... on Thing { str } } }")
    expected_trace = [
      "execute.graphql",
      (USING_C_PARSER ? "lex.graphql" : nil),
      "parse.graphql",
      "validate.graphql",
      "analyze.graphql",
      "Query.authorized.graphql",
      "Query.thing.graphql",
      "Thing.authorized.graphql",
      "Query.named.graphql",
      "Named.resolve_type.graphql",
      "Thing.authorized.graphql",
    ].compact
    assert_equal expected_trace, Appsignal.instrumented
  end

  describe "With Datadog Trace" do
    class AppsignalAndDatadogTestSchema < GraphQL::Schema
      query(AppsignalTraceTest::Query)
      trace_with(GraphQL::Tracing::DataDogTrace)
      trace_with(GraphQL::Tracing::AppsignalTrace)
      dataloader_lazy_setup(self)
      lazy_resolve(IntBox, :value)
    end

    class AppsignalAndDatadogReverseOrderTestSchema < GraphQL::Schema
      query(AppsignalTraceTest::Query)
      # Include these modules in different order than above:
      trace_with(GraphQL::Tracing::AppsignalTrace)
      trace_with(GraphQL::Tracing::DataDogTrace)
      dataloader_lazy_setup(self)
      lazy_resolve(IntBox, :value)
    end


    before do
      Datadog.clear_all
    end

    it "traces with both systems" do
      _res = AppsignalAndDatadogTestSchema.execute("{ int thing { str } named { ... on Thing { str } } }")
      expected_appsignal_trace = [
        "execute.graphql",
        (USING_C_PARSER ? "lex.graphql" : nil),
        "parse.graphql",
        "validate.graphql",
        "analyze.graphql",
        "Query.authorized.graphql",
        "Query.thing.graphql",
        "Thing.authorized.graphql",
        "Query.named.graphql",
        "Named.resolve_type.graphql",
        "Thing.authorized.graphql",
      ].compact

      expected_datadog_trace = [
        ["component", "graphql"],
        ["operation", "execute"],
        ["component", "graphql"],
        *(USING_C_PARSER ? [["operation", "lex"], ["component", "graphql"]] : []),
        ["operation", "parse"],
        ["selected_operation_name", nil],
        ["selected_operation_type", "query"],
        ["query_string", "{ int thing { str } named { ... on Thing { str } } }"],
        ["component", "graphql"],
        ["operation", "validate"]
      ]

      assert_equal expected_appsignal_trace, Appsignal.instrumented
      assert_equal expected_datadog_trace, Datadog::SPAN_TAGS
    end

    it "works when the modules are included in reverse order" do
      _res = AppsignalAndDatadogReverseOrderTestSchema.execute("{ int thing { str } named { ... on Thing { str } } }")
      expected_appsignal_trace = [
        (USING_C_PARSER ? "lex.graphql" : nil),
        "parse.graphql",
        "execute.graphql",
        "validate.graphql",
        "analyze.graphql",
        "Query.authorized.graphql",
        "Query.thing.graphql",
        "Thing.authorized.graphql",
        "Query.named.graphql",
        "Named.resolve_type.graphql",
        "Thing.authorized.graphql",
      ].compact

      expected_datadog_trace = [
        ["component", "graphql"],
        ["operation", "execute"],
        *(USING_C_PARSER ? [["component", "graphql"], ["operation", "lex"]] : []),
        ["component", "graphql"],
        ["operation", "parse"],
        ["selected_operation_name", nil],
        ["selected_operation_type", "query"],
        ["query_string", "{ int thing { str } named { ... on Thing { str } } }"],
        ["component", "graphql"],
        ["operation", "validate"]
      ]

      assert_equal expected_appsignal_trace, Appsignal.instrumented
      assert_equal expected_datadog_trace, Datadog::SPAN_TAGS
    end
  end
end
