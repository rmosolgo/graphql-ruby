# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Pagination::ArrayConnection do
  class TestSchema < GraphQL::Schema
    ITEMS = [
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
    ]

    class Item < GraphQL::Schema::Object
      field :name, String, null: false
    end

    class Query < GraphQL::Schema::Object
      # TODO don't require `connection: false`
      field :items, Item.connection_type, null: false, connection: false do
        argument :first, Integer, required: false
        argument :last, Integer, required: false
        argument :before, String, required: false
        argument :after, String, required: false
      end

      def items(**args)
        GraphQL::Pagination::ArrayConnection.new(ITEMS, context, max_page_size: 6, **args)
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
      assert get_page_info(res2, "hasPreviousPage")
      after_cursor2 = get_page_info(res2, "endCursor")

      res3 = exec_query(query_str, first: 30, after: after_cursor2)
      check_names(["Ginger", "Horseradish", "I Can't Believe It's Not Butter", "Jicama"], res3)
      refute get_page_info(res3, "hasNextPage")
      assert get_page_info(res3, "hasPreviousPage")
    end

    it "works with last/before" do
      res = exec_query(query_str, last: 3)
      check_names(["Horseradish", "I Can't Believe It's Not Butter", "Jicama"], res)
      refute get_page_info(res, "hasNextPage")
      assert get_page_info(res, "hasPreviousPage")
      before_cursor = get_page_info(res, "startCursor")

      res2 = exec_query(query_str, last: 3, before: before_cursor)
      check_names(["Eggplant", "Fennel", "Ginger"], res2)
      assert get_page_info(res2, "hasNextPage")
      assert get_page_info(res2, "hasPreviousPage")
      before_cursor2 = get_page_info(res2, "startCursor")

      res3 = exec_query(query_str, last: 10, before: before_cursor2)
      check_names(["Avocado", "Beet", "Cucumber", "Dill"], res3)
      assert get_page_info(res3, "hasNextPage")
      refute get_page_info(res3, "hasPreviousPage")
    end

    it "handles out-of-bounds cursors" do
      # It treats negative cursors like zero
      bogus_negative_cursor = Base64.strict_encode64("-10")
      res = exec_query(query_str, first: 3, after: bogus_negative_cursor)
      check_names(["Avocado", "Beet", "Cucumber"], res)

      # It returns nothing for cursors beyond the array
      bogus_huge_cursor = Base64.strict_encode64("100")
      res = exec_query(query_str, first: 3, after: bogus_huge_cursor)
      check_names([], res)
    end

    it "applies max_page_size to first and last" do
      res = exec_query(query_str, {})
      # Even though neither first nor last was provided, max_page_size was applied.
      check_names(["Avocado", "Beet", "Cucumber", "Dill", "Eggplant", "Fennel"], res)

      # max_page_size overrides first
      res = exec_query(query_str, first: 10)
      check_names(["Avocado", "Beet", "Cucumber", "Dill", "Eggplant", "Fennel"], res)

      # max_page_size overrides last
      res = exec_query(query_str, last: 10)
      check_names(["Eggplant", "Fennel", "Ginger", "Horseradish", "I Can't Believe It's Not Butter", "Jicama"], res)
    end
  end

  describe "customizing" do
    it "serves custom fields"
    it "applies local max-page-size settings"
  end
end
