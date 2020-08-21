# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::Relay::BaseConnection do
  module NonNullAbleNodeDummy
    class Node < GraphQL::Schema::Object
      field :some_field, String, null: true
    end

    class NodeEdgeType < GraphQL::Types::Relay::BaseEdge
      node_type(Node, null: false)
    end

    class NonNullableNodeEdgeConnectionType < GraphQL::Types::Relay::BaseConnection
      edge_type(NodeEdgeType, node_nullable: false)
    end

    class Query < GraphQL::Schema::Object
      field :connection, NonNullableNodeEdgeConnectionType, null: false
    end

    class Schema < GraphQL::Schema
      query Query
    end
  end

  it "node_nullable option is works" do
    res = NonNullAbleNodeDummy::Schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
    edge_type = res["data"]["__schema"]["types"].find { |t| t["name"] == "NonNullableNodeEdgeConnection" }
    nodes_field = edge_type["fields"].find { |f| f["name"] == "nodes" }
    assert_equal "NON_NULL",nodes_field["type"]["kind"]
    assert_equal "NON_NULL",nodes_field["type"]["ofType"]["ofType"]["kind"]
  end
end
