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
      edge_type(NodeEdgeType, node_nullable: false, edges_nullable: false)
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

  it "edges_nullable option is works" do
    res = NonNullAbleNodeDummy::Schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
    connection_type = res["data"]["__schema"]["types"].find { |t| t["name"] == "NonNullableNodeEdgeConnection" }
    edges_field = connection_type["fields"].find { |f| f["name"] == "edges" }
    assert_equal "NON_NULL",edges_field["type"]["kind"]
  end  

  it "never treats nodes like a connection" do
    type = Class.new(GraphQL::Schema::Object) do
      graphql_name "MissedConnection"
      field :id, "ID", null: false
    end

    refute type.connection_type.fields["nodes"].connection?
    refute type.connection_type.fields["edges"].type.unwrap.fields["node"].connection?
  end
end
