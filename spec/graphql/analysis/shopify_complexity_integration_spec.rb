# frozen_string_literal: true

require "spec_helper"
require "graphql/analysis/shopify_complexity"
require_relative "../../support/shopify_api_client"
require_relative "../../support/query_file_loader"
require_relative "../../support/shopify_complexity_result_reporter"

describe "ShopifyComplexity Integration Tests" do
  before do
    skip "SHOPIFY_ACCESS_TOKEN not set - skipping integration tests" unless ENV["SHOPIFY_ACCESS_TOKEN"]
  end

  it "estimates query costs accurately against real Shopify API" do
    schema_path = "spec/support/shopify/2025-07.graphql"
    schema = GraphQL::Schema.from_definition(schema_path)
    schema.complexity_cost_calculation_mode(:future)

    client = ShopifyApiClient.new
    query_dir = "spec/support/shopify/queries"

    # Load a random sample of queries (excluding fragment-only files)
    sample_size = ENV.fetch("SHOPIFY_SAMPLE_SIZE", "15").to_i
    queries = QueryFileLoader.load_random_queries(query_dir, sample_size)

    puts "\nLoaded #{queries.size} executable queries for testing"
    skip "No queries available for testing" if queries.empty?

    reporter = ShopifyComplexityResultReporter.new

    invalid_results = []

    queries.each_with_index do |query_info, idx|
      puts "\n[#{idx + 1}/#{queries.size}] Testing: #{query_info[:name]}"

      # Get default variables for this query
      variables = QueryFileLoader.default_variables(query_info[:content])

      # Calculate our estimated cost with field breakdown
      query = GraphQL::Query.new(schema, query_info[:content], variables: variables)
      our_result = GraphQL::Analysis.analyze_query(query, [GraphQL::Analysis::ShopifyComplexity]).first
      estimate_request_query_cost = our_result[:total]
      our_fields = our_result[:fields]

      # Execute against real Shopify API
      result = client.execute_query(query_info[:content], variables: variables)

      if result[:errors]
        error_message = result[:errors].map { |e| e["message"] }.join(", ")
        reporter.add_error(name: query_info[:name], error: error_message)
        puts "  API ERROR: #{result[:errors].first["message"]}"
        invalid_results << query_info[:name]
        next
      end

      actual_cost = result[:requested_query_cost]
      allowed_diff = [50, actual_cost * 0.1].max
      diff = estimate_request_query_cost - actual_cost
      percent_diff = actual_cost > 0 ? ((diff.to_f / actual_cost) * 100).round(1) : 0

      invalid_results << query_info[:name] if diff > allowed_diff

      reporter.add_result(
        name: query_info[:name],
        estimated: estimate_request_query_cost,
        actual: actual_cost,
        fields: result[:fields]
      )

      puts "  Estimated: #{estimate_request_query_cost}, Actual: #{actual_cost}, Diff: #{diff} (#{percent_diff}%)"

      if result[:fields] && diff.abs > 0
        puts "  \nShopify's field costs:"
        print_fields(result[:fields])
        puts "  \nOur field costs:"
        print_our_fields(our_fields)
      end

      # Be nice to Shopify's rate limits
      sleep 0.5
    end

    reporter.print_all(queries.size)

    assert_equal invalid_results.size, 0
  end

  def print_fields(fields)
    return unless fields
    fields.reject do |field|
      field["definedCost"] == 0 && field["requestedTotalCost"] == 0 && field["requestedChildrenCost"] == 0
    end.each do |field|
      name = field["path"].join(".")
      defined_cost = field["definedCost"]
      requested_total_cost = field["requestedTotalCost"]
      requested_children_cost = field["requestedChildrenCost"]

      puts "    #{name}: defined=#{defined_cost}, requested_total=#{requested_total_cost}, requested_children=#{requested_children_cost}"
    end
  end

  def print_our_fields(fields)
    return unless fields
    fields.reject do |field|
      field[:definedCost] == 0 && field[:requestedTotalCost] == 0 && field[:requestedChildrenCost] == 0
    end.each do |field|
      name = field[:path].join(".")
      defined_cost = field[:definedCost]
      requested_total_cost = field[:requestedTotalCost]
      requested_children_cost = field[:requestedChildrenCost]

      puts "    #{name}: defined=#{defined_cost}, requested_total=#{requested_total_cost}, requested_children=#{requested_children_cost}"
    end
  end
end
