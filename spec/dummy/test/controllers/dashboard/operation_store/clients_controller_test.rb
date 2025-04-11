# frozen_string_literal: true
require "test_helper"

if defined?(GraphQL::Pro)
  class DashboardOperationStoreClientsControllerTest < ActionDispatch::IntegrationTest
    def test_it_manages_clients
      assert_equal 0, DummySchema.operation_store.all_clients(page: 1, per_page: 1).total_count
      get graphql_dashboard.operation_store_clients_path
      assert_includes response.body, "0 Clients"
      assert_includes response.body, "To get started, create"

      get graphql_dashboard.new_operation_store_client_path
      assert_includes response.body, "New Client"

      post graphql_dashboard.operation_store_clients_path, params: {
        client: {
          name: "client-1",
          secret: "abcdefedcba"
        }
      }

      get graphql_dashboard.operation_store_clients_path
      assert_includes response.body, "1 Client"

      get graphql_dashboard.edit_operation_store_client_path(name: "client-1")
      assert_includes response.body, "abcdefedcba"

      patch graphql_dashboard.operation_store_client_path(name: "client-1"), params: { client: { secret: "123456789" } }
      get graphql_dashboard.edit_operation_store_client_path(name: "client-1")
      assert_includes response.body, "123456789"

      delete graphql_dashboard.operation_store_client_path(name: "client-1")
      assert_equal 0, DummySchema.operation_store.all_clients(page: 1, per_page: 1).total_count
    ensure
      DummySchema.operation_store.delete_client("client-1")
    end

    def test_it_paginates
      5.times do |i|
        DummySchema.operation_store.upsert_client("client-#{i}", "abcdef")
      end
      get graphql_dashboard.operation_store_clients_path(per_page: 2)
      assert_includes response.body, "5 Clients"
      assert_includes response.body, "?page=2&amp;per_page=2"
      assert_includes response.body, "disabled>« prev</button>"

      get graphql_dashboard.operation_store_clients_path(per_page: 2, page: 2)
      assert_includes response.body, "?page=1&amp;per_page=2"
      assert_includes response.body, "?page=3&amp;per_page=2"

      get graphql_dashboard.operation_store_clients_path(per_page: 2, page: 3)
      assert_includes response.body, "disabled>next »</button>"
      assert_includes response.body, "?page=2&amp;per_page=2"
    ensure
      5.times do |i|
        DummySchema.operation_store.delete_client("client-#{i}")
      end
    end

    def test_it_checks_installed
      get graphql_dashboard.new_operation_store_client_path, params: { schema: GraphQL::Schema }
      assert_includes response.body, "isn't installed for this schema yet"
    end
  end
end
