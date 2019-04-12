# frozen_string_literal: true
require "spec_helper"

if testing_mongoid?
  describe GraphQL::Pagination::MongoidRelationConnection do
    class Food
      include Mongoid::Document
      field :name, type: String
    end

    # Populate the DB
    Food.collection.drop
    ConnectionAssertions::NAMES.each { |n| Food.create(name: n) }

    class TestSchema < GraphQL::Schema
      default_max_page_size ConnectionAssertions::MAX_PAGE_SIZE

      class MongoidRelationConnectionWithTotalCount < GraphQL::Pagination::MongoidRelationConnection
        def total_count
          items.count
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
          GraphQL::Pagination::MongoidRelationConnection.new(relation, max_page_size: max_page_size_override)
        end

        field :custom_items, CustomItemConnection, null: false

        def custom_items
          relation = Food.all
          MongoidRelationConnectionWithTotalCount.new(relation)
        end
      end

      query(Query)
    end

    include ConnectionAssertions
  end
end
