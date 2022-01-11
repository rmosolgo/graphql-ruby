# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::Relay::HasNodeField do
  it "populates .owner when it's included" do
    query = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"
      include GraphQL::Types::Relay::HasNodeField
      include GraphQL::Types::Relay::HasNodesField
    end

    node_field = query.fields["node"]
    assert_equal query, node_field.owner
    assert_equal query, node_field.owner_type

    nodes_field = query.fields["nodes"]
    assert_equal query, nodes_field.owner
    assert_equal query, nodes_field.owner_type
  end

  it "warns when accessing legacy classes" do
    result = nil
    stdout, stderr = capture_io do
      result = GraphQL::Types::Relay::NodeField
    end

    assert_equal GraphQL::Types::Relay::DeprecatedNodeField, result
    assert_equal "", stdout
    expected_warning = "NodeField is deprecated, use `include GraphQL::Types::Relay::HasNodeField` instead."
    assert_includes stderr, expected_warning

    stdout, stderr = capture_io do
      result = GraphQL::Types::Relay::NodesField
    end

    assert_equal GraphQL::Types::Relay::DeprecatedNodesField, result
    assert_equal "", stdout
    expected_warning = "NodesField is deprecated, use `include GraphQL::Types::Relay::HasNodesField` instead."
    assert_includes stderr, expected_warning
  end
end
