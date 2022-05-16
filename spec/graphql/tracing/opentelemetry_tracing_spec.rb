# frozen_string_literal: true
require "spec_helper"

describe ::GraphQL::Tracing::OpenTelemetryTracing do
  module OpenTelemetryTest
    class Thing < GraphQL::Schema::Object
      implements GraphQL::Types::Relay::Node
    end

    class Query < GraphQL::Schema::Object
      include GraphQL::Types::Relay::HasNodeField

      field :int, Integer, null: false

      def int
        1
      end
    end

    class SchemaWithPerRequestTracing < GraphQL::Schema
      query(Query)
      use(GraphQL::Tracing::OpenTelemetryTracing)
      orphan_types(Thing)

      def self.object_from_id(_id, _ctx)
        :thing
      end

      def self.resolve_type(_type, _obj, _ctx)
        Thing
      end
    end
  end

  before do
    OpenTelemetry::Instrumentation::GraphQL::Instrumentation.clear_all
  end

  it "captures all keys when tracing is enabled in config and in query execution context" do
    query = GraphQL::Query.new(OpenTelemetryTest::SchemaWithPerRequestTracing, '{ node(id: "1") { __typename } }')
    query.context.namespace(:opentelemetry)[:enable_platform_field] = true
    query.context.namespace(:opentelemetry)[:enable_platform_authorized] = true
    query.context.namespace(:opentelemetry)[:enable_platform_resolve_type] = true

    query.result

    assert_span("Query.authorized")
    assert_span("Query.node")
    assert_span("Node.resolve_type")
    assert_span("Thing.authorized")
    assert_span("DynamicFields.authorized")
  end

  it "does not capture the keys when tracing is not enabled in config but is enabled in query execution context" do
    OpenTelemetry::Instrumentation::GraphQL::Instrumentation.instance.stub(:config, {
      schemas: [],
      enable_platform_field: false,
      enable_platform_authorized: false,
      enable_platform_resolve_type: false
    }) do

      query = GraphQL::Query.new(OpenTelemetryTest::SchemaWithPerRequestTracing, '{ node(id: "1") { __typename } }')
      query.context.namespace(:opentelemetry)[:enable_platform_field] = true
      query.context.namespace(:opentelemetry)[:enable_platform_authorized] = true
      query.context.namespace(:opentelemetry)[:enable_platform_resolve_type] = true
  
      query.result

      refute_span("Query.authorized")
      refute_span("Query.node")
      refute_span("Node.resolve_type")
      refute_span("Thing.authorized")
      refute_span("DynamicFields.authorized")
    end
  end

  it "does not capture any key when tracing is not enabled in config and tracing is not set in context" do
    OpenTelemetry::Instrumentation::GraphQL::Instrumentation.instance.stub(:config, {
      schemas: [],
      enable_platform_field: false,
      enable_platform_authorized: false,
      enable_platform_resolve_type: false
    }) do

      query = GraphQL::Query.new(OpenTelemetryTest::SchemaWithPerRequestTracing, '{ node(id: "1") { __typename } }')

      query.result

      refute_span("Query.authorized")
      refute_span("Query.node")
      refute_span("Node.resolve_type")
      refute_span("Thing.authorized")
      refute_span("DynamicFields.authorized")
    end
  end

  it "does not capture any key when tracing is not enabled in config and context" do
    OpenTelemetry::Instrumentation::GraphQL::Instrumentation.instance.stub(:config, {
      schemas: [],
      enable_platform_field: false,
      enable_platform_authorized: false,
      enable_platform_resolve_type: false
    }) do
  
      query = GraphQL::Query.new(OpenTelemetryTest::SchemaWithPerRequestTracing, '{ node(id: "1") { __typename } }')
      query.context.namespace(:opentelemetry)[:enable_platform_field] = false
      query.context.namespace(:opentelemetry)[:enable_platform_authorized] = false
      query.context.namespace(:opentelemetry)[:enable_platform_resolve_type] = false

      query.result
  
      refute_span("Query.authorized")
      refute_span("Query.node")
      refute_span("Node.resolve_type")
      refute_span("Thing.authorized")
      refute_span("DynamicFields.authorized")
    end
  end

  it "captures all keys when tracing is enabled in config but is not set in context" do
    query = GraphQL::Query.new(OpenTelemetryTest::SchemaWithPerRequestTracing, '{ node(id: "1") { __typename } }')

    query.result
  
    assert_span("Query.authorized")
    assert_span("Query.node")
    assert_span("Node.resolve_type")
    assert_span("Thing.authorized")
    assert_span("DynamicFields.authorized")
  end

  it "does not capture any key when tracing is enabled in config but is not enabled in context" do
    query = GraphQL::Query.new(OpenTelemetryTest::SchemaWithPerRequestTracing, '{ node(id: "1") { __typename } }')
    query.context.namespace(:opentelemetry)[:enable_platform_field] = false
    query.context.namespace(:opentelemetry)[:enable_platform_authorized] = false
    query.context.namespace(:opentelemetry)[:enable_platform_resolve_type] = false

    query.result
  
    refute_span("Query.authorized")
    refute_span("Query.node")
    refute_span("Node.resolve_type")
    refute_span("Thing.authorized")
    refute_span("DynamicFields.authorized")
  end

  private

  def assert_span(span)
    assert OpenTelemetry::Instrumentation::GraphQL::Instrumentation::EVENTS.include?(span)
  end

  def refute_span(span)
    refute OpenTelemetry::Instrumentation::GraphQL::Instrumentation::EVENTS.include?(span)
  end
end
