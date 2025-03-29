# frozen_string_literal: true
require "test_helper"

class DashboardOperationStoreIndexEntriesControllerTest < ActionDispatch::IntegrationTest
  def test_it_shows_entries
    DummySchema.operation_store.upsert_client("client-1", "abcdef")
    DummySchema.operation_store.add(body: "query GetTypename { __type(name: \"Query\") { name @skip(if: true) } }", operation_alias: "GetTypename", client_name: "client-1")

    get graphql_dashboard.operation_store_index_entries_path
    assert_includes response.body, "Query.__type.name"
    assert_includes response.body, "7 entries"

    get graphql_dashboard.operation_store_index_entries_path(q: "Query")
    assert_includes response.body, "3 results"
    assert_includes response.body, ">Query</a>"
    assert_includes response.body, ">Query.__type</a>"
    assert_includes response.body, ">Query.__type.name</a>"

    get graphql_dashboard.operation_store_index_entries_path(q: "Query", per_page: 1, page: 2)
    assert_includes response.body, "3 results"
    refute_includes response.body, ">Query</a>"
    assert_includes response.body, ">Query.__type</a>"
    refute_includes response.body, ">Query.__type.name</a>"

    get graphql_dashboard.operation_store_index_entry_path(name: "Query.__type.name")
    assert_includes response.body, "GetTypename"
  ensure
    DummySchema.operation_store.delete_client("client-1")
  end
end
