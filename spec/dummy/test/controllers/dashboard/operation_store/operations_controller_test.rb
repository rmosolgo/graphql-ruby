# frozen_string_literal: true
require "test_helper"

class DashboardOperationStoreOperationsControllerTest < ActionDispatch::IntegrationTest
  def teardown
    DummySchema.operation_store.delete_client("client-1")
    DummySchema.operation_store.delete_client("client-2")
    super
  end
  def test_it_lists_and_shows_operations
    get graphql_dashboard.operation_store_operations_path
    assert_includes response.body, "Add your first stored operations with"

    get graphql_dashboard.operation_store_operations_path(client_name: "client-5000")
    assert_includes response.body, "Add your first stored operations with"

    os = DummySchema.operation_store
    os.upsert_client("client-1", "abcdef")
    os.add(body: "query GetTypename { __typename }", operation_alias: "GetTypename", client_name: "client-1")
    os.add(body: "query GetAliasedTypename { t: __typename }", operation_alias: "get-aliased-typename", client_name: "client-1")

    os.upsert_client("client-2", "abcdef")
    os.add(body: "query GetTypename { __typename }", operation_alias: "GetTypename2", client_name: "client-2")

    get graphql_dashboard.operation_store_operations_path
    assert_includes response.body, "2 Operations"
    assert_includes response.body, "GetTypename"
    assert_includes response.body, "GetAliasedTypename"

    get graphql_dashboard.operation_store_operations_path(client_name: "client-2")
    assert_includes response.body, "1 Operations"
    assert_includes response.body, "GetTypename"
    refute_includes response.body, "GetAliasedTypename"

    get graphql_dashboard.operation_store_operation_path(digest: "4cd12cc333c91f78e8f781933ecc783d")
    assert_includes response.body, "GetAliasedTypename"
    assert_includes response.body, "client-1"
    assert_includes response.body, "Query.__typename"
  end

  def test_it_archives_and_unarchives_operations
    skip "Todo"
  end

  def test_it_sorts_operations
    skip "TODO -- merge into previous test"
  end

  def test_it_checks_installed
    get graphql_dashboard.new_operation_store_client_path, params: { schema: GraphQL::Schema }
    assert_includes response.body, "isn't installed for this schema yet"
  end
end
