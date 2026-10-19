# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Pagination::ArrayConnection do
  ARRAY_ITEMS = ConnectionAssertions::NAMES.map { |n| { name: n } }

  class ArrayTestConnectionWithTotalCount < GraphQL::Pagination::ArrayConnection
    def total_count
      items.size
    end
  end

  let(:schema) {
    ConnectionAssertions.build_schema(
      connection_class: GraphQL::Pagination::ArrayConnection,
      total_count_connection_class: ArrayTestConnectionWithTotalCount,
      get_items: -> { ARRAY_ITEMS }
    )
  }

  include ConnectionAssertions

  it "rejects malformed cursors" do
    query = <<~GRAPHQL
      query($after: String!) {
        items(first: 3, after: $after) { nodes { name } }
      }
    GRAPHQL

    ["-1", "0", "abc", "1e10"].each do |cursor|
      encoded_cursor = ConnectionAssertions::NonceEnabledEncoder.encode(cursor)
      result = schema.execute(query, variables: { "after" => encoded_cursor })
      assert_nil result.dig("data", "items", "nodes")
      assert_includes result["errors"].first["message"], "Invalid cursor"
    end
  end
end
