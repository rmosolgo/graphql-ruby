# frozen_string_literal: true

# A shared module for testing ArrayConnection, RelationConnection,
# DatasetConnection and MongoRelationConnection.
#
# The test must implement `TestSchema` to serve the queries below with the expected results.
module ConnectionAssertions
  MAX_PAGE_SIZE = 6
  NAMES = [
    "Avocado",
    "Beet",
    "Cucumber",
    "Dill",
    "Eggplant",
    "Fennel",
    "Ginger",
    "Horseradish",
    "I Can't Believe It's Not Butter",
    "Jicama",
  ]

  def self.included(child_module)
    child_module.class_exec do
      def exec_query(query_str, variables)
        TestSchema.execute(query_str, variables: variables)
      end

      def get_page_info(result, page_info_field)
        result["data"]["items"]["pageInfo"][page_info_field]
      end

      def assert_names(expected_names, result)
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
          assert_names(["Avocado", "Beet", "Cucumber"], res)
          assert get_page_info(res, "hasNextPage")
          refute get_page_info(res, "hasPreviousPage")
          after_cursor = get_page_info(res, "endCursor")

          res2 = exec_query(query_str, first: 3, after: after_cursor)
          assert_names(["Dill", "Eggplant", "Fennel"], res2)
          assert get_page_info(res2, "hasNextPage")
          assert get_page_info(res2, "hasPreviousPage")
          after_cursor2 = get_page_info(res2, "endCursor")

          res3 = exec_query(query_str, first: 30, after: after_cursor2)
          assert_names(["Ginger", "Horseradish", "I Can't Believe It's Not Butter", "Jicama"], res3)
          refute get_page_info(res3, "hasNextPage")
          assert get_page_info(res3, "hasPreviousPage")
        end

        it "works with last/before" do
          res = exec_query(query_str, last: 3)
          assert_names(["Horseradish", "I Can't Believe It's Not Butter", "Jicama"], res)
          refute get_page_info(res, "hasNextPage")
          assert get_page_info(res, "hasPreviousPage")
          before_cursor = get_page_info(res, "startCursor")

          res2 = exec_query(query_str, last: 3, before: before_cursor)
          assert_names(["Eggplant", "Fennel", "Ginger"], res2)
          assert get_page_info(res2, "hasNextPage")
          assert get_page_info(res2, "hasPreviousPage")
          before_cursor2 = get_page_info(res2, "startCursor")

          res3 = exec_query(query_str, last: 10, before: before_cursor2)
          assert_names(["Avocado", "Beet", "Cucumber", "Dill"], res3)
          assert get_page_info(res3, "hasNextPage")
          refute get_page_info(res3, "hasPreviousPage")
        end

        it "handles out-of-bounds cursors" do
          # It treats negative cursors like zero
          bogus_negative_cursor = Base64.strict_encode64("-10")
          res = exec_query(query_str, first: 3, after: bogus_negative_cursor)
          assert_names(["Avocado", "Beet", "Cucumber"], res)

          # It returns nothing for cursors beyond the array
          bogus_huge_cursor = Base64.strict_encode64("100")
          res = exec_query(query_str, first: 3, after: bogus_huge_cursor)
          assert_names([], res)
        end

        it "handles negative firsts and lasts by treating them as zero" do
          res = exec_query(query_str, first: -3)
          assert_names([], res)

          res = exec_query(query_str, last: -9)
          assert_names([], res)
        end

        it "applies max_page_size to first and last" do
          res = exec_query(query_str, {})
          # Even though neither first nor last was provided, max_page_size was applied.
          assert_names(["Avocado", "Beet", "Cucumber", "Dill", "Eggplant", "Fennel"], res)

          # max_page_size overrides first
          res = exec_query(query_str, first: 10)
          assert_names(["Avocado", "Beet", "Cucumber", "Dill", "Eggplant", "Fennel"], res)

          # max_page_size overrides last
          res = exec_query(query_str, last: 10)
          assert_names(["Eggplant", "Fennel", "Ginger", "Horseradish", "I Can't Believe It's Not Butter", "Jicama"], res)
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

          assert_names(["Avocado", "Beet", "Cucumber"], res)
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

          assert_names(["Avocado", "Beet", "Cucumber"], res)

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

          assert_names(["Avocado", "Beet", "Cucumber", "Dill", "Eggplant", "Fennel", "Ginger"], res)
        end
      end
    end
  end
end
