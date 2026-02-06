# frozen_string_literal: true
require "test_helper"

class DashboardLandingsControllerTest < ActionDispatch::IntegrationTest
  def test_it_doesnt_load_autoloads_files
    result = `BUNDLE_GEMFILE=#{ENV["BUNDLE_GEMFILE"]} ruby ./test_autoloads.rb`
    assert_includes result, "No autoloaded constants were found during the boot process."
  end

  def test_it_shows_a_landing_page_with_local_static_asset_links
    get graphql_dashboard.root_path
    assert_includes response.body, "Welcome to the GraphQL-Ruby Dashboard"
    assert_includes response.body, '<link rel="stylesheet" href="/dash/statics/bootstrap-5.3.3.min.css" media="screen" />', "it doesn't use config.asset_host"
  end

  def test_it_shows_version_and_schema_info
    get graphql_dashboard.root_path
    assert_includes response.body, "GraphQL-Ruby v#{GraphQL::VERSION}"
    assert_includes response.body, "<code>DummySchema</code>"
    get graphql_dashboard.root_path, params: { schema: "NotInstalledSchema" }
    assert_includes response.body, "<code>NotInstalledSchema</code>"
  end
end
