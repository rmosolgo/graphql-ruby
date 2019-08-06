# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Relay::Edge do
  it "inspects nicely" do
    connection = OpenStruct.new(parent: "Parent")
    edge = GraphQL::Relay::Edge.new("Node", connection)
    assert_equal '#<GraphQL::Relay::Edge ("Parent" => "Node")>', edge.inspect
  end
end
