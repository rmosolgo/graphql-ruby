# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::Relay::BaseConnection do
  module NonNullAbleNodeDummy
    class Node < GraphQL::Schema::Object
      field :some_field, String
    end

    class NodeEdgeType < GraphQL::Types::Relay::BaseEdge
      node_type(Node, null: false)
    end

    class NonNullableNodeEdgeConnectionType < GraphQL::Types::Relay::BaseConnection
      edge_type(NodeEdgeType, node_nullable: false, edges_nullable: false, edge_nullable: false)
    end

    class NonNullableEdgeClassOverrideConnectionType < GraphQL::Types::Relay::BaseConnection
      edges_nullable(false)
      edge_nullable(false)
      node_nullable(false)
    end

    class Query < GraphQL::Schema::Object
      field :connection, NonNullableNodeEdgeConnectionType, null: false
    end

    class NoNodesFieldClassOverrideConnectionType < GraphQL::Types::Relay::BaseConnection
      has_nodes_field(false)
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

  it "supports class-level edges_nullable config" do
    assert_equal false, NonNullAbleNodeDummy::NonNullableEdgeClassOverrideConnectionType.edges_nullable
    assert_equal false, NonNullAbleNodeDummy::NonNullableEdgeClassOverrideConnectionType.edge_nullable
    assert_equal false, NonNullAbleNodeDummy::NonNullableEdgeClassOverrideConnectionType.node_nullable
  end

  it "edge_nullable option is works" do
    res = NonNullAbleNodeDummy::Schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
    connection_type = res["data"]["__schema"]["types"].find { |t| t["name"] == "NonNullableNodeEdgeConnection" }
    edges_field = connection_type["fields"].find { |f| f["name"] == "edges" }
    assert_equal "NON_NULL",edges_field["type"]["ofType"]["ofType"]["kind"]
  end

  it "never treats nodes like a connection" do
    type = Class.new(GraphQL::Schema::Object) do
      graphql_name "MissedConnection"
      field :id, "ID", null: false
    end

    refute type.connection_type.fields["nodes"].connection?
    refute type.connection_type.fields["edges"].type.unwrap.fields["node"].connection?
  end

  it "supports class-level nodes_field config" do
    assert_equal false, NonNullAbleNodeDummy::NoNodesFieldClassOverrideConnectionType.has_nodes_field
  end

  it "Supports extra kwargs for edges" do
    connection = Class.new(GraphQL::Types::Relay::BaseConnection) do
      edge_type(GraphQL::Schema::Object.edge_type, edges_field_options: { deprecation_reason: "passing extra args" })
    end

    field = connection.fields["edges"]
    assert_equal "passing extra args", field.deprecation_reason
  end
end
