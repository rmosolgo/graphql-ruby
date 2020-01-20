# frozen_string_literal: true

# A shared module for testing ArrayConnection, RelationConnection,
# DatasetConnection and MongoRelationConnection.
#
# The test must implement `schema` to serve the queries below with the expected results.
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

  def self.build_schema(get_items:, connection_class:, total_count_connection_class:)
    Class.new(GraphQL::Schema) do
      use GraphQL::Pagination::Connections
      use GraphQL::Execution::Interpreter

      default_max_page_size ConnectionAssertions::MAX_PAGE_SIZE

      # Make a way to get local variables (passed in as args)
      # into method resolvers below
      class << self
        attr_accessor :get_items, :connection_class, :total_count_connection_class
      end

      self.get_items = get_items
      self.connection_class = connection_class
      self.total_count_connection_class = total_count_connection_class

      item = Class.new(GraphQL::Schema::Object) do
        graphql_name "Item"
        field :name, String, null: false
      end

      custom_item_edge = Class.new(GraphQL::Types::Relay::BaseEdge) do
        node_type item
        graphql_name "CustomItemEdge"
      end

      custom_item_connection = Class.new(GraphQL::Types::Relay::BaseConnection) do
        graphql_name "CustomItemConnection"
        edge_type custom_item_edge
        field :total_count, Integer, null: false
      end

      query = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"
        field :items, item.connection_type, null: false do
          argument :max_page_size_override, Integer, required: false
        end

        def items(max_page_size_override: nil)
          context.schema.connection_class.new(get_items, max_page_size: max_page_size_override)
        end

        field :custom_items, custom_item_connection, null: false

        def custom_items
          context.schema.total_count_connection_class.new(get_items)
        end

        field :limited_items, item.connection_type, null: false, max_page_size: 2

        def limited_items
          get_items
        end

        private

        def get_items
          context.schema.get_items.call
        end
      end

      query(query)

      use GraphQL::Execution::Interpreter
      use GraphQL::Analysis::AST
    end
  end

  def self.included(child_module)
    child_module.class_exec do
      def exec_query(query_str, variables)
        schema.execute(query_str, variables: variables)
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
          assert_equal true, get_page_info(res, "hasNextPage")
          assert_equal false, get_page_info(res, "hasPreviousPage")

          # max_page_size overrides first
          res = exec_query(query_str, first: 10)
          assert_names(["Avocado", "Beet", "Cucumber", "Dill", "Eggplant", "Fennel"], res)
          assert_equal true, get_page_info(res, "hasNextPage")
          assert_equal false, get_page_info(res, "hasPreviousPage")

          # max_page_size overrides last
          res = exec_query(query_str, last: 10)
          assert_names(["Eggplant", "Fennel", "Ginger", "Horseradish", "I Can't Believe It's Not Butter", "Jicama"], res)
          assert_equal false, get_page_info(res, "hasNextPage")
          assert_equal true, get_page_info(res, "hasPreviousPage")
        end
      end

      describe "customizing" do
        it "serves custom fields" do
          res = schema.execute <<-GRAPHQL
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
          res = schema.execute <<-GRAPHQL
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
          res = schema.execute <<-GRAPHQL
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

        it "applies a field-level max-page-size configuration" do
          res = schema.execute <<-GRAPHQL
          {
            items: limitedItems(first: 10) {
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
          assert_names(["Avocado", "Beet"], res)
        end
      end
    end
  end
end
