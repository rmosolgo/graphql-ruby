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

  it "paginates duplicate items by position" do
    items = ["a", "a", "a", "b"]
    context = GraphQL::Query.new(schema, "{ __typename }").context
    after = nil
    nodes = []
    cursors = []

    4.times do
      connection = GraphQL::Pagination::ArrayConnection.new(items, first: 1, after: after, context: context)
      nodes.concat(connection.nodes)
      after = connection.end_cursor
      cursors << after
    end

    assert_equal items, nodes
    assert_equal 4, cursors.uniq.length

    connection = GraphQL::Pagination::ArrayConnection.new(items, first: 4, context: context)
    assert_respond_to connection, :cursor_for_position
    assert_equal connection.end_cursor, connection.cursor_for_position(connection.nodes.last, 3)
    assert_equal 4, connection.edges.map(&:cursor).uniq.length
    error = assert_raises(GraphQL::ExecutionError) { connection.cursor_for("missing") }
    assert_equal "Can't generate a cursor for an item outside this connection", error.message
  end

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
