# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Pagination::ArrayConnection do
  class TestSchema < GraphQL::Schema
    default_max_page_size 6

    class ArrayConnectionWithTotalCount < GraphQL::Pagination::ArrayConnection
      def total_count
        items.size
      end
    end

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

    class CustomItemEdge < GraphQL::Types::Relay::BaseEdge
      node_type Item
      graphql_name "CustomItemEdge"
    end

    class CustomItemConnection < GraphQL::Types::Relay::BaseConnection
      edge_type CustomItemEdge
      field :total_count, Integer, null: false
    end

    class Query < GraphQL::Schema::Object
      field :items, Item.connection_type, null: false do
        argument :max_page_size_override, Integer, required: false
      end

      def items(max_page_size_override: nil)
        GraphQL::Pagination::ArrayConnection.new(ITEMS, max_page_size: max_page_size_override)
      end

      field :custom_items, CustomItemConnection, null: false

      def custom_items
        ArrayConnectionWithTotalCount.new(ITEMS)
      end
    end

    query(Query)
  end

  include ConnectionAssertions
end
