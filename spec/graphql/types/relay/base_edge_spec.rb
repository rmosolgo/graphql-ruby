# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::Relay::BaseEdge do
  module NonNullableDummy
    class NonNullableNode < GraphQL::Schema::Object
      field :some_field, String, null: true
    end

    class NonNullableNodeEdgeType < GraphQL::Types::Relay::BaseEdge
      node_type(NonNullableNode, null: false)
    end

    class NonNullableNodeEdgeConnectionType < GraphQL::Types::Relay::BaseConnection
      edge_type(NonNullableNodeEdgeType, nodes_field: false)
    end

    class Query < GraphQL::Schema::Object
      field :connection, NonNullableNodeEdgeConnectionType, null: false
    end

    class Schema < GraphQL::Schema
      query Query
    end
  end

  it "runs the introspection query and the result contains a edge field that has non-nullable node" do
    res = NonNullableDummy::Schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
    assert res
    edge_type = res["data"]["__schema"]["types"].find { |t| t["name"] == "NonNullableNodeEdge" }
    node_field = edge_type["fields"].find { |f| f["name"] == "node" }
    assert_equal "NON_NULL", node_field["type"]["kind"]
    assert_equal "NonNullableNode", node_field["type"]["ofType"]["name"]
  end
end
