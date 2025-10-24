# frozen_string_literal: true

require "net/http"
require "json"

# Simple client to execute GraphQL queries against Shopify Admin API
class ShopifyApiClient
  API_VERSION = "2025-10"

  def initialize(access_token: ENV["SHOPIFY_ACCESS_TOKEN"])
    raise "SHOPIFY_ACCESS_TOKEN not set" unless access_token
    @access_token = access_token
  end

  # Execute a query and return the cost information
  # @param query_string [String] The GraphQL query
  # @param variables [Hash] Query variables
  # @return [Hash] { actual_cost:, requested_cost:, throttle_status:, data:, errors: }
  def execute_query(query_string, variables: {})
    uri = URI("https://#{ENV["SHOPIFY_STORE"]}/admin/api/#{API_VERSION}/graphql.json")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request["X-Shopify-Access-Token"] = @access_token
    request["Shopify-GraphQL-Cost-Debug"] = "1"

    body = { query: query_string }
    body[:variables] = variables unless variables.empty?
    request.body = JSON.generate(body)

    response = http.request(request)
    parsed = JSON.parse(response.body)

    extensions = parsed["extensions"] || {}
    cost = extensions["cost"] || {}

    {
      actual_query_cost: cost["actualQueryCost"],
      requested_query_cost: cost["requestedQueryCost"],
      throttle_status: cost["throttleStatus"],
      fields: cost["fields"],
      data: parsed["data"],
      errors: parsed["errors"]
    }
  rescue => e
    {
      actual_cost: nil,
      requested_cost: nil,
      error: e.message,
      errors: [{ message: e.message }]
    }
  end
end
