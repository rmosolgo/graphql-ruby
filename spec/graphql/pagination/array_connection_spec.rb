# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Pagination::ArrayConnection do
  class TestSchema < GraphQL::Schema
    class Item < GraphQL::Schema::Object
      field :name, String, null: false
    end

    class Query < GraphQL::Schema::Object
      field :items, Item.connection_type, null: false, connection: false do
        argument :first, Integer, required: false
        argument :last, Integer, required: false
        argument :before, String, required: false
        argument :after, String, required: false
      end

      def items(first: nil, after: nil, last: nil, before: nil)
        GraphQL::Pagination::ArrayConnection.new([
          { name: "Avocado" },
          { name: "Beet" },
          { name: "Cucumber" },
          { name: "Dill" },
          { name: "Eggplant" },
          { name: "Fennel" },
          { name: "Ginger"},
          { name: "Horseradish" },
          { name: "I Can't Believe It's Not Butter" },
          { name: "Jicama" },
        ], context, first: first, after: after, last: last, before: before)
      end
    end

    query(Query)
  end

  def exec_query(query_str, variables)
    TestSchema.execute(query_str, variables: variables)
  end

  def get_page_info(result, page_info_field)
    result["data"]["items"]["pageInfo"][page_info_field]
  end

  def check_names(expected_names, result)
    nodes_names = result["data"]["items"]["nodes"].map { |n| n["name"] }
    assert_equal expected_names, nodes_names, "The nodes shortcut field has expected names"
    edges_names = result["data"]["items"]["edges"].map { |n| n["node"]["name"] }
    assert_equal expected_names, edges_names, "The edges.node has expected names"
  end

  describe "cursor-based pagination" do
    let(:query_str) { <<-GRAPHQL
      query($first: Int, $after: String, $last: Int, $before: String) {
        items(first: $first, after: $after, last: $last, before: $before) {
          nodes {
            name
          }
          edges {
            node {
              name
            }
            cursor
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          }
        }
      }
      GRAPHQL
    }

    it "works with first/after" do
      res = exec_query(query_str, first: 3)
      check_names(["Avocado", "Beet", "Cucumber"], res)
      assert get_page_info(res, "hasNextPage")
      refute get_page_info(res, "hasPreviousPage")
      after_cursor = get_page_info(res, "endCursor")

      res2 = exec_query(query_str, first: 3, after: after_cursor)
      check_names(["Dill", "Eggplant", "Fennel"], res2)
      assert get_page_info(res2, "hasNextPage")
      refute get_page_info(res2, "hasPreviousPage")
      after_cursor2 = get_page_info(res2, "endCursor")

      res3 = exec_query(query_str, first: 30, after: after_cursor2)
      check_names(["Ginger", "Horseradish", "I Can't Believe It's Not Butter", "Jicama"], res3)
      refute get_page_info(res3, "hasNextPage")
      refute get_page_info(res3, "hasPreviousPage")
    end

    it "works with last/before"
    it "handles out-of-bounds cursors"
    it "applies max_page_size to first and last"
  end

  describe "customizing" do
    it "serves custom fields"
    it "applies local max-page-size settings"
  end
end
