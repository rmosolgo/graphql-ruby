# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/install_generator"
require "generators/graphql/detailed_trace_generator"

class GraphQLGeneratorsDetailedTraceGeneratorTest < Rails::Generators::TestCase
  tests Graphql::Generators::DetailedTraceGenerator
  destination File.expand_path("../../../tmp/dummy", File.dirname(__FILE__))

  setup do
    prepare_destination
    FileUtils.cd(File.join(destination_root, '..')) do
      `rails new dummy --skip-active-record --skip-test-unit --skip-spring --skip-bundle --skip-webpack-install`
      Graphql::Generators::InstallGenerator.start(["--skip-graphiql"], { destination_root: destination_root })
    end
  end

  test "it creates a migration, installs a route, and adds schema configuration" do
    run_generator
    assert_migration "db/migrate/create_graphql_detailed_traces"
    assert_file "app/graphql/dummy_schema.rb" do |content|
      assert_includes content, "
  use GraphQL::Tracing::DetailedTrace, limit: 50

  # When this returns true, DetailedTrace will trace the query
  # Could use `query.context`, `query.selected_operation_name`, `query.query_string` here
  # Could call out to Flipper, etc
  def self.detailed_trace?(query)
    rand <= 0.000_1 # one in ten thousand
  end
"
    end

    assert_file "config/routes.rb" do |content|
      assert_includes content, "mount GraphQL::Dashboard, at: \"/graphql/dashboard\", schema: \"DummySchema\""
    end

    assert_file "Gemfile", /google-protobuf/
  end

  test "it doesn't duplicate dashboard setup" do
    routes_path = File.expand_path("config/routes.rb", destination_root)
    existing_routes = File.read(routes_path)
    new_routes = existing_routes.sub("draw do\n", "draw do\n  mount DummySchema.dashboard\n")
    File.write(routes_path, new_routes)
    run_generator
    assert_file "config/routes.rb" do |content|
      refute_includes content, "mount GraphQL::Dashboard"
    end
  end

  test "it sets up Redis, too" do
    run_generator(["--redis"])
    assert_no_migration "db/migrate/create_graphql_detailed_traces"
    assert_file "app/graphql/dummy_schema.rb" do |content|
      assert_includes content, "use GraphQL::Tracing::DetailedTrace, redis: raise(\"TODO: pass a connection to a persistent redis database\"), limit: 50\n\n"
    end

    assert_file "config/routes.rb" do |content|
      assert_includes content, "mount GraphQL::Dashboard, at: \"/graphql/dashboard\", schema: \"DummySchema\""
    end
  end
end
