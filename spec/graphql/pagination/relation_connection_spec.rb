# frozen_string_literal: true
require "spec_helper"

if testing_rails?
  describe GraphQL::Pagination::RelationConnection do
    class Food < ActiveRecord::Base
    end

    [
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
    ].each { |f| Food.create!(f) }

    class TestSchema < GraphQL::Schema
      default_max_page_size 6

      class RelationConnectionWithTotalCount < GraphQL::Pagination::RelationConnection
        def total_count
          items.unscope(:order).count(:all)
        end
      end

      class FoodItem < GraphQL::Schema::Object
        field :name, String, null: false
      end

      class CustomItemEdge < GraphQL::Types::Relay::BaseEdge
        node_type FoodItem
        graphql_name "CustomItemEdge"
      end

      class CustomItemConnection < GraphQL::Types::Relay::BaseConnection
        edge_type CustomItemEdge
        field :total_count, Integer, null: false
      end

      class Query < GraphQL::Schema::Object
        field :items, FoodItem.connection_type, null: false do
          argument :max_page_size_override, Integer, required: false
        end

        def items(max_page_size_override: nil)
          relation = Food.all
          GraphQL::Pagination::RelationConnection.new(relation, max_page_size: max_page_size_override)
        end

        field :custom_items, CustomItemConnection, null: false

        def custom_items
          relation = Food.all
          RelationConnectionWithTotalCount.new(relation)
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
      it "serves custom fields" do
        res = TestSchema.execute <<-GRAPHQL
        {
          items: customItems(first: 3) {
            nodes {
              name
            }
            edges {
              node  {
                name
              }
            }
            totalCount
          }
        }
        GRAPHQL

        check_names(["Avocado", "Beet", "Cucumber"], res)
        assert_equal 10, res["data"]["items"]["totalCount"]
      end

      it "applies local max-page-size settings" do
        # Smaller default:
        res = TestSchema.execute <<-GRAPHQL
        {
          items(first: 10, maxPageSizeOverride: 3) {
            nodes {
              name
            }
            edges {
              node {
                name
              }
            }
          }
        }
        GRAPHQL

        check_names(["Avocado", "Beet", "Cucumber"], res)

        # Larger than the default:
        res = TestSchema.execute <<-GRAPHQL
        {
          items(first: 10, maxPageSizeOverride: 7) {
            nodes {
              name
            }
            edges {
              node {
                name
              }
            }
          }
        }
        GRAPHQL

        check_names(["Avocado", "Beet", "Cucumber", "Dill", "Eggplant", "Fennel", "Ginger"], res)
      end
    end
  end
end
