# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Pagination::ArrayConnection do
  ITEMS = ConnectionAssertions::NAMES.map { |n| { name: n } }

  class ArrayConnectionWithTotalCount < GraphQL::Pagination::ArrayConnection
    def total_count
      items.size
    end
  end

  let(:schema) {
    ConnectionAssertions.build_schema(
      connection_class: GraphQL::Pagination::ArrayConnection,
      total_count_connection_class: ArrayConnectionWithTotalCount,
      get_items: -> { ITEMS }
    )
  }

  include ConnectionAssertions
end
