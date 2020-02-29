# frozen_string_literal: true
require "spec_helper"

if testing_rails?
  describe GraphQL::Pagination::SequelDatasetConnection do
    class SequelFood < Sequel::Model(:foods)
    end

    if SequelFood.empty? # Can overlap with ActiveRecordRelationConnection test
      ConnectionAssertions::NAMES.each { |n| SequelFood.create(name: n) }
    end

    class SequelDatasetConnectionWithTotalCount < GraphQL::Pagination::SequelDatasetConnection
      def total_count
        items.count
      end
    end

    let(:schema) {
      ConnectionAssertions.build_schema(
        connection_class: GraphQL::Pagination::SequelDatasetConnection,
        total_count_connection_class: SequelDatasetConnectionWithTotalCount,
        get_items: -> { SequelFood.dataset }
      )
    }

    include ConnectionAssertions
  end
end
