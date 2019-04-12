# frozen_string_literal: true
require "spec_helper"

if testing_rails?
  describe GraphQL::Pagination::ActiveRecordRelationConnection do
    class Food < ActiveRecord::Base
    end

    if Food.empty?
      ConnectionAssertions::NAMES.each { |n| Food.create!(name: n) }
    end

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

    include ConnectionAssertions
  end
end
