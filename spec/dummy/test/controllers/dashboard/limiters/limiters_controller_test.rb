# frozen_string_literal: true
require "test_helper"

class DashboardLimitersLimitersControllerTest < ActionDispatch::IntegrationTest
  def test_it_checks_installed
    get graphql_dashboard.limiters_limiter_path("runtime", { schema: "GraphQL::Schema" })
    assert_includes response.body, CGI::escapeHTML("Rate limiters aren't installed on this schema yet.")
  end

  def test_it_shows_limiters
    Redis.new(db: DummySchema::DB_NUMBER).flushdb

    3.times do
      DummySchema.execute("{ sleep(seconds: 0.02) }", context: { limiter_key: "client-1" }).to_h
    end
    4.times do
      DummySchema.execute("{ sleep(seconds: 0.110) }", context: { limiter_key: "client-2" }).to_h
    end

    get graphql_dashboard.limiters_limiter_path("runtime")
    assert_includes response.body, "<span class=\"data\">4</span>"
    assert_includes response.body, "<span class=\"data\">3</span>"
    assert_includes response.body, "Disable Soft Limiting"

    patch graphql_dashboard.limiters_limiter_path("runtime")
    get graphql_dashboard.limiters_limiter_path("runtime")
    assert_includes response.body, "Enable Soft Limiting"

    get graphql_dashboard.limiters_limiter_path("active_operations")
    assert_includes response.body, "It looks like this limiter isn't installed yet."

  end
end
