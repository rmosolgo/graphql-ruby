# frozen_string_literal: true
require "spec_helper"

if testing_rails?
  describe GraphQL::Pagination::ActiveRecordRelationConnection do
    class Food < ActiveRecord::Base
    end

    if Food.count == 0 # Backwards-compat version of `.none?`
      ConnectionAssertions::NAMES.each { |n| Food.create!(name: n) }
    end

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

    TestSchema = ConnectionAssertions.build_schema(
      connection_class: GraphQL::Pagination::ActiveRecordRelationConnection,
      total_count_connection_class: RelationConnectionWithTotalCount,
      get_items: -> {
        if Food.respond_to?(:scoped)
          Food.scoped # Rails 3-friendly version of .all
        else
          Food.all
        end
      }
    )

    include ConnectionAssertions
  end
end
