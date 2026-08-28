# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Pagination::Connection do
  describe "was_authorized_by_scope_ites?" do
    it "doesn't raise an error for missing runtime state and it updates it if context is assigned later" do
      context = GraphQL::Query.new(GraphQL::Schema, "{ __typename }").context
      conn = GraphQL::Pagination::Connection.new([], context: context)
      assert_nil conn.was_authorized_by_scope_items?

      conn.context = context
      assert_nil conn.was_authorized_by_scope_items?

      Fiber[:__graphql_runtime_info] = { context.query => OpenStruct.new(was_authorized_by_scope_items: true) }
      conn.context = context
      assert_equal true, conn.was_authorized_by_scope_items?
    ensure
      Fiber[:__graphql_runtime_info] = nil
    end
  end
end

describe GraphQL::Pagination::RelationConnection do
  it "loads nodes without context" do
    connection_class = Class.new(GraphQL::Pagination::RelationConnection) do
      private

      def limited_nodes
        items
      end
    end

    assert_equal [1, 2, 3], connection_class.new([1, 2, 3]).nodes
  end
end
