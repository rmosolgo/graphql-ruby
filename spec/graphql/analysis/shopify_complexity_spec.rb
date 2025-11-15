# frozen_string_literal: true

require "spec_helper"
require "graphql/analysis/shopify_complexity"

describe GraphQL::Analysis::ShopifyComplexity do
  let(:schema_path) { "spec/support/shopify/2025-07.graphql" }
  let(:schema) { GraphQL::Schema.from_definition(schema_path) }

  it "calculates complexity 9 for the sample order query" do
    schema.complexity_cost_calculation_mode(:future)

    order_query = File.read("spec/support/shopify/queries/Order.graphql")
    query = GraphQL::Query.new(
      schema,
      order_query,
      variables: { "id" => "gid://shopify/Order/12345" }
    )

    result = GraphQL::Analysis.analyze_query(query, [GraphQL::Analysis::ShopifyComplexity]).first
    assert_equal 9, result[:total]
  end

  it "calculates complexity 629 for the Orders query" do
    schema.complexity_cost_calculation_mode(:future)

    orders_query = File.read("spec/support/shopify/queries/Orders.graphql")
    variables = {
      "query" => "(id:1)OR(id:2)",
      "first" => 250,
    }

    query = GraphQL::Query.new(
      schema,
      orders_query,
      variables: variables,
    )

    result = GraphQL::Analysis.analyze_query(query, [GraphQL::Analysis::ShopifyComplexity]).first
    assert_equal 629, result[:total]
  end
end


