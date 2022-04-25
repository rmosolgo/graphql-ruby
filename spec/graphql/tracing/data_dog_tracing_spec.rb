# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::DataDogTracing do
  module DataDogTest
    class Query < GraphQL::Schema::Object
      include GraphQL::Types::Relay::HasNodeField

      field :int, Integer, null: false

      def int
        1
      end
    end

    class TestSchema < GraphQL::Schema
      query(Query)
      use(GraphQL::Tracing::DataDogTracing)
    end
  end

  before do
    Datadog.clear_all
  end

  it "falls back to a :tracing_fallback_transaction_name when provided" do
    DataDogTest::TestSchema.execute("{ int }", context: { tracing_fallback_transaction_name: "Abcd" })
    assert_equal ["Abcd"], Datadog::SPAN_RESOURCE_NAMES
  end

  it "does not use the :tracing_fallback_transaction_name if an operation name is present" do
    DataDogTest::TestSchema.execute(
      "query Ab { int }",
      context: { tracing_fallback_transaction_name: "Cd" }
    )
    assert_equal ["Ab"], Datadog::SPAN_RESOURCE_NAMES
  end

  it "does not set resource if no value can be derived" do
    DataDogTest::TestSchema.execute("{ int }")
    assert_equal [], Datadog::SPAN_RESOURCE_NAMES
  end

  it "sets component and operation tags" do
    DataDogTest::TestSchema.execute("{ int }")
    assert_includes Datadog::SPAN_TAGS, ['component', 'graphql']
    assert_includes Datadog::SPAN_TAGS, ['operation', 'execute_multiplex']
  end
end
