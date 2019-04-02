# frozen_string_literal: true
require "spec_helper"

if testing_rails?
  describe GraphQL::Pagination::ActiveRecordRelationConnection do
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

      class RelationConnectionWithTotalCount < GraphQL::Pagination::ActiveRecordRelationConnection
        def total_count
          if items.respond_to?(:unscope)
            items.unscope(:order).count(:all)
          else
            # rails 3
            items.count
          end
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
          GraphQL::Pagination::ActiveRecordRelationConnection.new(relation, max_page_size: max_page_size_override)
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

    include ConnectionAssertions
  end
end
