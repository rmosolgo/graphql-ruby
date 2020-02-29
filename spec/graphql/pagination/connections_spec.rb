# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Pagination::Connections do
  ITEMS = ConnectionAssertions::NAMES.map { |n| { name: n } }

  class ArrayConnectionWithTotalCount < GraphQL::Pagination::ArrayConnection
    def total_count
      items.size
    end
  end

  let(:base_schema) {
    ConnectionAssertions.build_schema(
      connection_class: GraphQL::Pagination::ArrayConnection,
      total_count_connection_class: ArrayConnectionWithTotalCount,
      get_items: -> { ITEMS }
    )
  }

  # These wouldn't _work_, I just need to test `.wrap`
  class SetConnection < GraphQL::Pagination::ArrayConnection; end
  class HashConnection < GraphQL::Pagination::ArrayConnection; end
  class OtherArrayConnection < GraphQL::Pagination::ArrayConnection; end

  let(:schema) do
    other_base_schema = Class.new(base_schema) do
      connections.add(Set, SetConnection)
    end

    Class.new(other_base_schema) do
      connections.add(Hash, HashConnection)
      connections.add(Array, OtherArrayConnection)
    end
  end

  it "returns connections by class, using inherited mappings and local overrides" do
    field_defn = OpenStruct.new(max_page_size: 10)

    set_wrapper = schema.connections.wrap(field_defn, Set.new([1,2,3]), {}, nil)
    assert_instance_of SetConnection, set_wrapper

    hash_wrapper = schema.connections.wrap(field_defn, {1 => :a, 2 => :b}, {}, nil)
    assert_instance_of HashConnection, hash_wrapper

    array_wrapper = schema.connections.wrap(field_defn, [1,2,3], {}, nil)
    assert_instance_of OtherArrayConnection, array_wrapper
  end

  it "uses passed-in wrappers" do
    field_defn = OpenStruct.new(max_page_size: 10)

    assert_raises GraphQL::Pagination::Connections::ImplementationMissingError do
      schema.connections.wrap(field_defn, Set.new([1,2,3]), {}, nil, wrappers: {})
    end
  end
end
