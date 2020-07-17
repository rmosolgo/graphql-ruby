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

  class NonceEnabledEncoder
    class << self
      def encode(value, nonce: false)
        "#{JSON.dump([value])}#{nonce ? "+nonce" : ""}"
      end

      def decode(value, nonce: false)
        if nonce
          value = value.sub(/\+nonce$/, "")
        end
        JSON.parse(value).first
      end
    end
  end

  def self.build_schema(get_items:, connection_class:, total_count_connection_class:)
    base_schema = Class.new(GraphQL::Schema) do
      use GraphQL::Pagination::Connections
    end

    Class.new(base_schema) do
      use GraphQL::Execution::Interpreter

      default_max_page_size ConnectionAssertions::MAX_PAGE_SIZE
      cursor_encoder(NonceEnabledEncoder)

      # Make a way to get local variables (passed in as args)
      # into method resolvers below
      class << self
        attr_accessor :get_items, :connection_class, :total_count_connection_class, :custom_connection_class_with_custom_edge
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

        field :parent_class, String, null: false

        def parent_class
          object.parent.class.inspect
        end

        field :node_class_name, String, null: false
      end

      custom_edge_class = Class.new(GraphQL::Pagination::Connection::Edge) do
        def node_class_name
          node.class.name
        end
      end

      custom_item_connection = Class.new(GraphQL::Types::Relay::BaseConnection) do
        graphql_name "CustomItemConnection"
        edge_type custom_item_edge, edge_class: custom_edge_class
        field :total_count, Integer, null: false
      end

      if connection_class
        self.custom_connection_class_with_custom_edge = Class.new(connection_class) do
          const_set(:Edge, custom_edge_class)
        end
      end

      custom_items_with_custom_edge = Class.new(GraphQL::Types::Relay::BaseConnection) do
        graphql_name "AnotherCustomItemConnection"
        edge_type custom_item_edge
      end

      query = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"
        field :items, item.connection_type, null: false do
          argument :max_page_size_override, Integer, required: false
        end

        def items(max_page_size_override: :no_value)
          if max_page_size_override != :no_value
            context.schema.connection_class.new(get_items, max_page_size: max_page_size_override)
          else
            # don't manually apply the wrapper when it's not required -- check automatic wrapping.
            get_items
          end
        end

        field :custom_items, custom_item_connection, null: false

        def custom_items
          context.schema.total_count_connection_class.new(get_items)
        end

        if connection_class
          field :custom_items_with_custom_edge, custom_items_with_custom_edge, null: false

          def custom_items_with_custom_edge
            context.schema.custom_connection_class_with_custom_edge.new(get_items)
          end
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
          bogus_negative_cursor = NonceEnabledEncoder.encode("-10")
          res = exec_query(query_str, first: 3, after: bogus_negative_cursor)
          assert_names(["Avocado", "Beet", "Cucumber"], res)

          # It returns nothing for cursors beyond the array
          bogus_huge_cursor = NonceEnabledEncoder.encode("100")
          res = exec_query(query_str, first: 3, after: bogus_huge_cursor)
          assert_names([], res)
        end

        it "handles negative firsts and lasts by treating them as zero" do
          res = exec_query(query_str, first: -3)
          assert_names([], res)

          res = exec_query(query_str, last: -9)
          assert_names([], res)
        end

        it "handles blank cursors by treating them as nil" do
          res = exec_query(query_str, first: 3, after: "")
          assert_names(["Avocado", "Beet", "Cucumber"], res)

          res = exec_query(query_str, last: 3, before: "")
          assert_names(["Horseradish", "I Can't Believe It's Not Butter", "Jicama"], res)
        end

        it "builds cursors with nonce" do
          res = exec_query(query_str, first: 3, after: "")
          end_cursor = get_page_info(res, "endCursor")
          assert end_cursor.end_with?("+nonce"), "it added nonce to #{end_cursor.inspect}"
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
          res = schema.execute <<-GRAPHQL, root_value: :something
          {
            items: customItems(first: 3) {
              nodes {
                name
              }
              edges {
                node  {
                  name
                }
                parentClass
                nodeClassName
              }
              totalCount
            }
          }
          GRAPHQL
          assert_names(["Avocado", "Beet", "Cucumber"], res)
          assert_equal 10, res["data"]["items"]["totalCount"]
          edge = res["data"]["items"]["edges"][0]
          # Since this connection hangs off `Query`, the root value is the parent.
          assert_equal "Symbol", edge["parentClass"]
          if schema.get_items
            node_class_name = schema.get_items.call.first.class.name
            assert_instance_of String, node_class_name
            assert_equal node_class_name, edge["nodeClassName"]
          end
        end

        it "uses custom ::Edge classes" do
          skip "Not supported" if schema.connection_class.nil?
          res = schema.execute <<-GRAPHQL, root_value: :something
          {
            items: customItemsWithCustomEdge(first: 3) {
              nodes {
                name
              }
              edges {
                node  {
                  name
                }
                nodeClassName
              }
            }
          }
          GRAPHQL
          assert_names(["Avocado", "Beet", "Cucumber"], res)
          edge = res["data"]["items"]["edges"][0]
          node_class_name = schema.get_items.call.first.class.name
          assert_instance_of String, node_class_name
          assert_equal node_class_name, edge["nodeClassName"]
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

          # Unlimited
          res = schema.execute <<-GRAPHQL
          {
            items(first: 100, maxPageSizeOverride: null) {
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
          assert_names(NAMES, res)
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
