# frozen_string_literal: true
require "test_helper"

class DashboardLimitersLimitersControllerTest < ActionDispatch::IntegrationTest
  def test_it_checks_installed
    get graphql_dashboard.limiters_limiter_path("runtime", { schema: "GraphQL::Schema" })
    assert_includes response.body, CGI::escapeHTML("Rate limiters aren't installed on this schema yet.")
  end

  def test_it_shows_limiters
    skip "TODO"
  end
end
